import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_bar_item.dart';
import 'consent_manager.dart';
import 'countdown_timer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rewarded Example',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Redirige a RewardedExample cuando el botón es presionado
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RewardedExample()),
            );
          },
          child: const Text('Ir a la vista de Alan Graph'),
        ),
      ),
    );
  }
}

class RewardedExample extends StatefulWidget {
  const RewardedExample({super.key});

  @override
  RewardedExampleState createState() => RewardedExampleState();
}

class RewardedExampleState extends State<RewardedExample> {
  final _consentManager = ConsentManager();
  final CountdownTimer _countdownTimer = CountdownTimer();
  var _showWatchVideoButton = false;
  var _gamePaused = false;
  var _gameOver = false;
  var _isMobileAdsInitializeCalled = false;
  var _isPrivacyOptionsRequired = false;
  var _coins = 0;
  RewardedAd? _rewardedAd;

  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  @override
  void initState() {
    super.initState();

    _consentManager.gatherConsent((consentGatheringError) {
      if (consentGatheringError != null) {
        debugPrint(
            "${consentGatheringError.errorCode}: ${consentGatheringError.message}");
      }

      _startNewGame();
      _getIsPrivacyOptionsRequired();
      _initializeMobileAdsSDK();
    });

    _initializeMobileAdsSDK();

    _countdownTimer.addListener(() => setState(() {
          if (_countdownTimer.isComplete) {
            _gameOver = true;
            _showWatchVideoButton = true;
            _coins += 1;
          } else {
            _showWatchVideoButton = false;
          }
        }));
  }

  void _startNewGame() {
    _countdownTimer.start();
    _gameOver = false;
    _gamePaused = false;
  }

  void _pauseGame() {
    if (_gameOver || _gamePaused) {
      return;
    }
    _countdownTimer.pause();
    _gamePaused = true;
  }

  void _resumeGame() {
    if (_gameOver || !_gamePaused) {
      return;
    }
    _countdownTimer.resume();
    _gamePaused = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 221, 225, 226),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 225, 223, 230),
        title: const Text('Alan Graph Special PDF'),
        actions: _appBarActions(),
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  Text(
                    'Alan Graph',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 45),
                  Image.asset('assets/alan_graph.jpg', height: 190),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_countdownTimer.isComplete
                    ? ' '
                    : 'Conectando espere ${_countdownTimer.timeLeft} segundos...'),
                Visibility(
                  visible: _countdownTimer.isComplete,
                  child: TextButton(
                    onPressed: () {
                      _startNewGame();
                      _loadAd();
                    },
                    child: const Text(' Quiero mi Alan Special Grpah'),
                  ),
                ),
                Visibility(
                  visible: _showWatchVideoButton,
                  child: TextButton(
                    onPressed: () {
                      setState(() => _showWatchVideoButton = false);

                      _rewardedAd?.show(onUserEarnedReward:
                          (AdWithoutView ad, RewardItem rewardItem) {
                        print('Reward amount: ${rewardItem.amount}');
                        setState(() => _coins += rewardItem.amount.toInt());
                      });
                    },
                    child: const Text(
                        'Ver video para obtener 10 Alan Graph exportaciones'),
                  ),
                )
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Text('Alan Graph: $_coins'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _appBarActions() {
    var array = [AppBarItem(AppBarItem.adInpsectorText, 0)];

    if (_isPrivacyOptionsRequired) {
      array.add(AppBarItem(AppBarItem.privacySettingsText, 1));
    }

    return <Widget>[
      PopupMenuButton<AppBarItem>(
        itemBuilder: (context) => array
            .map((item) => PopupMenuItem<AppBarItem>(
                  value: item,
                  child: Text(
                    item.label,
                  ),
                ))
            .toList(),
        onSelected: (item) {
          _pauseGame();
          switch (item.value) {
            case 0:
              MobileAds.instance.openAdInspector((error) {
                _resumeGame();
              });
              break;
            case 1:
              _consentManager.showPrivacyOptionsForm((formError) {
                if (formError != null) {
                  debugPrint("${formError.errorCode}: ${formError.message}");
                }
                _resumeGame();
              });
              break;
          }
        },
      ),
    ];
  }

  void _loadAd() async {
    var canRequestAds = await _consentManager.canRequestAds();
    if (!canRequestAds) {
      return;
    }

    RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
                onAdShowedFullScreenContent: (ad) {},
                onAdImpression: (ad) {},
                onAdFailedToShowFullScreenContent: (ad, err) {
                  ad.dispose();
                },
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                },
                onAdClicked: (ad) {});

            _rewardedAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
          },
        ));
  }

  void _getIsPrivacyOptionsRequired() async {
    if (await _consentManager.isPrivacyOptionsRequired()) {
      setState(() {
        _isPrivacyOptionsRequired = true;
      });
    }
  }

  void _initializeMobileAdsSDK() async {
    if (_isMobileAdsInitializeCalled) {
      return;
    }

    if (await _consentManager.canRequestAds()) {
      _isMobileAdsInitializeCalled = true;
      MobileAds.instance.initialize();
      _loadAd();
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _countdownTimer.dispose();
    super.dispose();
  }
}
