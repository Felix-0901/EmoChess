// App localization strings for English and Traditional Chinese
import 'package:flutter/material.dart';

/// Localization class for EmoChess app
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      // App
      'appName': 'EmoChess',
      'appTagline': 'Learn Chess, Grow Emotions',
      'appDescription':
          'Chess is not just about winning.\nIt\'s about growing and learning!',

      // Home Screen
      'playChess': 'Play Chess',
      'breathingExercise': 'Breathing Exercise',
      'settings': 'Settings',

      // Auth
      'login': 'Login',
      'register': 'Register',
      'welcomeBack': 'Welcome back!',
      'createAccount': 'Create your account',
      'displayName': 'Display Name',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'emailRequired': 'Please enter your email',
      'emailInvalid': 'Please enter a valid email',
      'passwordRequired': 'Please enter your password',
      'passwordTooShort': 'Password must be at least 6 characters',
      'confirmPasswordRequired': 'Please confirm your password',
      'passwordMismatch': 'Passwords do not match',
      'displayNameRequired': 'Please enter your display name',
      'alreadyHaveAccount': 'Already have an account? Login',
      'noAccount': 'No account yet? Register',
      'logout': 'Logout',
      'logoutConfirm': 'Are you sure you want to logout?',
      'cancel': 'Cancel',

      // Emotion Check-in
      'howAreYouFeeling': 'How Are You Feeling?',
      'beforeWeStart': 'Before we start,\nlet me know how you feel!',
      'noWrongAnswer': 'There\'s no wrong answer.',
      'letsPlay': 'Let\'s Play!',

      // Emotions
      'happy': 'Happy',
      'neutral': 'Calm',
      'frustrated': 'Frustrated',
      'howDoYouFeel': 'How do you feel?',
      'chatHint': 'Type a short reply...',

      // Game Screen
      'emoChess': 'EmoChess',
      'undoMove': 'Undo Move',
      'takeABreath': 'Take a Breath',
      'whiteTurn': 'White\'s Turn',
      'blackTurn': 'Black\'s Turn',
      'check': 'Check!',
      'whiteWins': 'White Wins!',
      'blackWins': 'Black Wins!',
      'draw': 'It\'s a Draw!',
      'leaveGame': 'Leave Game?',
      'leaveGameMessage':
          'Your progress will not be saved.\nAre you sure you want to leave?',
      'stay': 'Stay',
      'leave': 'Leave',

      // Breathing Screen
      'breathingExerciseTitle': 'Breathing Exercise',
      'takeAMoment': 'Take a moment to relax',
      'followTheCircle': 'Follow the circle with your breath',
      'findComfortable': 'Find a comfortable position',
      'pressStart': 'Press start when you\'re ready',
      'startBreathing': 'Start Breathing',
      'iFeelBetter': 'I Feel Better',
      'greatJob': 'Great job! You did well.',
      'inhale': 'Breathe In',
      'hold': 'Hold',
      'exhale': 'Breathe Out',

      // Settings Screen
      'language': 'Language',
      'game': 'Game',
      'showMoveHints': 'Show Move Hints',
      'showMoveHintsDesc': 'Highlight legal moves',
      'version': 'Version',
      'aboutDesc': 'Emotion-focused chess learning for ASD children',
      'help': 'Help',
      'tutorial': 'Tutorial',
      'tutorialDesc': 'Learn how to use EmoChess',
      'tutorialStep1': '1. Check in with your emotions before playing',
      'tutorialStep2': '2. Play chess and express how you feel',
      'tutorialStep3': '3. Use breathing exercises when frustrated',
      'tutorialStep4': '4. Your AI buddy will support you along the way',
      'gotIt': 'Got it!',

      // Profile & Stats
      'gamesPlayed': 'Played',
      'wins': 'Wins',
      'winRate': 'Win Rate',

      // AI Companion Messages
      'aiMsgFrustrated1':
          'It\'s okay to feel frustrated. Would you like a breathing break?',
      'aiMsgFrustrated2': 'Chess can be tricky! That\'s how we learn and grow.',
      'aiMsgFrustrated3':
          'Even the best players face challenges. You\'re doing great!',
      'aiMsgFrustrated4': 'Take a deep breath. There\'s no rush.',
      'aiMsgFrustrated5': 'Remember, making mistakes is part of learning!',
      'aiMsgCheck1': 'Your king is in check! Take your time to think.',
      'aiMsgCheck2': 'Check! Look for a way to protect your king.',
      'aiMsgCheck3': 'Don\'t worry about the check. You\'ve got this!',
      'aiMsgMistake1': 'That\'s okay! Every move teaches us something.',
      'aiMsgMistake2': 'Mistakes help us become better players.',
      'aiMsgMistake3': 'No worries! Let\'s see what happens next.',
      'aiMsgHappy1': 'Great job! You\'re doing wonderfully!',
      'aiMsgHappy2': 'I love seeing you enjoy the game!',
      'aiMsgHappy3': 'Fantastic thinking! Keep it up!',
      'aiMsgHappy4': 'You\'re having fun, and that\'s what matters!',
      'aiMsgNeutral1': 'Take your time with this move.',
      'aiMsgNeutral2': 'You\'re doing well! Keep thinking.',
      'aiMsgNeutral3': 'Every move is a learning opportunity.',
      'aiMsgNeutral4': 'Chess is a journey, not a race.',
      'chessBuddy': 'Chess Buddy',
      'imOkay': 'I\'m okay',

      // AI & Analysis - NEW
      'aiThinking': 'AI is thinking...',
      'emotionAnalysis': 'Emotion Analysis',
      'gameHistory': 'Game History',
      'noGamesYet': 'No games yet',
      'playFirstGame': 'Play your first game!',
      'gameDuration': 'Duration',
      'totalMoves': 'Total Moves',
      'startAnalysis': 'Start Analysis',
      'analyzing': 'Analyzing...',
      'analysisComplete': 'Analysis Complete',
      'emotionTrend': 'Emotion Trend',
      'emotionDistribution': 'Emotion Distribution',
      'analysisSummary': 'Summary',
      'chatHistory': 'Chat History',
      'moveHistory': 'Move History',
      'emotionEvents': 'Emotion Events',
      'totalChats': 'Total Chats',
      'initialEmotion': 'Initial Emotion',
      'finalEmotion': 'Final Emotion',
      'result': 'Result',
      'resultWin': 'Win',
      'resultLoss': 'Loss',
      'resultDraw': 'Draw',
      'resultAbandoned': 'Abandoned',
      'resultUnknown': 'Unknown',
      'analysisNotFound': 'Record not found',
      'analysisNoEmotion': 'No emotion data yet.',
      'analysisNoChat': 'No chat records yet.',
      'analysisNoMoves': 'No moves recorded yet.',
      'gameCompleted': 'Game Completed',
      'gameAbandoned': 'Game Abandoned',

      // Companion Interactions - NEW
      'yes': 'Yes',
      'no': 'No',
      'howIsTheGame': 'How is the game going so far?',
      'enjoyingChess': 'Are you enjoying this game?',
      'needHelp': 'Would you like a hint?',
      'greatMove': 'That was a great move!',
      'thinkingWell': 'You\'re thinking well!',
      'choiceGreat': 'Great!',
      'choiceOkay': 'It\'s okay',
      'choiceHard': 'It\'s hard',
      'choiceHelp': 'I need help',
      'responseGreat': 'Wonderful! Keep having fun!',
      'responseOkay': 'That\'s fine! Take your time.',
      'responseHard': 'It\'s okay to find it hard. You\'re learning!',
      // Analysis Interactions
      'aiMsgCheckTrigger': 'Careful! You\'re in check! Can you get out safely?',
      'aiMsgCaptureTrigger': 'Nice capture!',
      'aiMsgOpeningTrigger':
          'Solid opening so far! Do you have a specific plan in mind?',
      'aiMsgStrategyTrigger': 'What is your main goal right now?',
      'aiMsgStrategySafety':
          'That looks like a bold move. Are you sure your King is safe?',

      // Teaching Moments
      'aiTeachPawn':
          'Did you know? Pawns can be very powerful when they work together!',
      'aiTeachKnight':
          'Knights love to jump! They can reach squares that other pieces cannot.',
      'aiTeachCastle': 'Castling keeps your King safe. Have you tried it?',
      'aiTeachCenter':
          'Controlling the center gives you more options! Try to place pieces there.',
      'aiTeachProtect':
          'Remember to protect your pieces! A good player always looks out for their team.',

      // Welcome
      'aiWelcome':
          "Hey there, friend! Let's play some chess together. Remember, it's not about winning - it's about having fun!",

      'choiceAttack': 'Attack',
      'choiceDefend': 'Defend',
      'choiceDevelop': 'Develop',
      'choiceControl': 'Control Center',

      // Game Over Dialog
      'playAgain': 'Play Again',
      'viewEmotionAnalysis': 'View Emotion Analysis',
      'returnHome': 'Return Home',
      'youWin': 'You Won!',
      'gameOver': 'Game Over',
      'congratsMessage': 'Amazing! You played really well!',
      'goodEffortMessage': 'Great effort! Every game helps you improve.',
      'drawMessage': 'A draw! Both players played well.',

      // AI Fallback Messages
      'aiFallbackCheck1':
          'Careful! You are in check. Take a moment to find a safe move.',
      'aiFallbackCheck2': 'Check! Look at your options to protect your king.',
      'aiFallbackCheck3': 'Your king needs protection. Can you find a way out?',
      'aiFallbackCapture1': 'Nice capture! You are playing well.',
      'aiFallbackCapture2': 'Great move! Taking pieces helps you win.',
      'aiFallbackCapture3': 'Well done! Every capture counts.',
      'aiFallbackFrustrated':
          'I can see you are working hard. How are you feeling right now?',
      'aiFallbackNeedHelp': 'I need help',
      'aiFallbackHelpResponse':
          'That is okay! Let me give you a tip: look at all your pieces and think about which one can do the most.',
      'aiFallbackImFine': 'I am fine',
      'aiFallbackFineResponse': 'Great to hear! Keep going at your own pace.',
      'aiFallbackWantBreak': 'I want a break',
      'aiFallbackBreakResponse':
          'That is a smart choice. Taking breaks helps us think better!',
      'aiFallbackTeach1':
          'Did you know? Controlling the center of the board gives you more options.',
      'aiFallbackTeach2':
          'Knights are tricky! They can jump over other pieces.',
      'aiFallbackTeach3':
          'Pawns are small but mighty. They can become any piece if they reach the other side!',
      'aiFallbackTeach4':
          'Protecting your pieces is just as important as attacking.',
      'aiFallbackTeach5':
          'Castling is a great way to keep your king safe. Have you tried it?',
      'aiFallbackEncourage1':
          'Take your time. Good moves come from careful thinking.',
      'aiFallbackEncourage2':
          'You are doing well! Every game makes you better.',
      'aiFallbackEncourage3': 'Nice work! What are you planning next?',
      'aiFallbackEncourage4':
          'Keep it up! Chess is about patience and practice.',
      'aiFallbackHappyAmazing':
          'You are doing amazing! I can tell you are enjoying this.',
      'aiFallbackHappyWonderful': 'Wonderful thinking! Keep having fun!',
      'aiFallbackHappyGreat': 'Great job! Your enthusiasm is inspiring.',
      'aiFallbackWelcome':
          'Hello, friend! Let us play some chess together. Remember, it is not about winning - it is about having fun and learning!',
      'aiFallbackStrategyQ': 'What would you like to focus on right now?',
      'aiFallbackAttackResponse':
          'Going on the attack! Look for pieces that can threaten the opponent.',
      'aiFallbackDefendResponse':
          'Good thinking! A strong defense makes winning easier.',
      'aiFallbackDevelopResponse':
          'Smart choice! Getting your pieces active gives you more options.',
      'aiFallbackControlResponse':
          'Controlling the center is key! It gives your pieces more room to move.',
      'aiFallbackGenericThanks':
          'Thanks for sharing! Keep playing and having fun.',
      'aiFallbackBreakIdea':
          'Taking a break is a great idea! Come back when you feel ready.',

      // Welcome Greeting (Interactive)
      'welcomeGreeting':
          'Hi there! I am your chess buddy. I am happy to play with you!',
      'welcomeChoiceReady': 'I am ready!',
      'welcomeResponseReady':
          'Awesome! You go first with the white pieces. Take your time and have fun!',
      'welcomeChoiceNervous': 'A little nervous',
      'welcomeResponseNervous':
          'That is totally okay! We will take it slow. Just enjoy the game, no pressure at all.',
      'welcomeChoiceThinking': 'Still thinking',
      'welcomeResponseThinking':
          'No rush! When you are ready, just move any piece you like. I am here to help!',

      // Generic Interactive Choices
      'choiceThanks': 'Thanks!',
      'responseThanks': 'You are welcome! Keep focusing.',
      'choiceCool': 'Cool!',
      'responseCool': 'Right? Chess is awesome.',
      'choiceInteresting': 'Interesting',
      'responseInteresting': 'I thought so too! Learning new things is fun.',
      'choiceGoodPoint': 'Good point',
      'responseGoodPoint': 'Glad that helps! Let\'s see what happens next.',
      'choiceGotIt': 'Got it',
      'responseGotIt': 'Perfect! Use that knowledge in your next move.',
    },
    'zh': {
      // App
      'appName': 'EmoChess 情緒棋局',
      'appTagline': '學習西洋棋，成長情緒',
      'appDescription': '西洋棋不只是輸贏。\n它是成長與學習！',

      // Home Screen
      'playChess': '開始下棋',
      'breathingExercise': '呼吸練習',
      'settings': '設定',

      // Auth
      'login': '登入',
      'register': '註冊',
      'welcomeBack': '歡迎回來！',
      'createAccount': '建立你的帳號',
      'displayName': '顯示名稱',
      'password': '密碼',
      'confirmPassword': '確認密碼',
      'emailRequired': '請輸入 Email',
      'emailInvalid': '請輸入有效的 Email',
      'passwordRequired': '請輸入密碼',
      'passwordTooShort': '密碼至少需要 6 個字元',
      'confirmPasswordRequired': '請再次輸入密碼',
      'passwordMismatch': '兩次密碼不一致',
      'displayNameRequired': '請輸入顯示名稱',
      'alreadyHaveAccount': '已有帳號？登入',
      'noAccount': '還沒有帳號？註冊',
      'logout': '登出',
      'logoutConfirm': '確定要登出嗎？',
      'cancel': '取消',

      // Emotion Check-in
      'howAreYouFeeling': '你現在感覺如何？',
      'beforeWeStart': '開始之前，\n讓我知道你的感受！',
      'noWrongAnswer': '沒有標準答案。',
      'letsPlay': '開始遊戲！',

      // Emotions
      'happy': '開心',
      'neutral': '平靜',
      'frustrated': '沮喪',
      'howDoYouFeel': '你感覺如何？',
      'chatHint': '輸入簡短回覆…',

      // Game Screen
      'emoChess': 'EmoChess 情緒棋局',
      'undoMove': '悔棋',
      'takeABreath': '深呼吸',
      'whiteTurn': '白棋的回合',
      'blackTurn': '黑棋的回合',
      'check': '將軍！',
      'whiteWins': '白棋獲勝！',
      'blackWins': '黑棋獲勝！',
      'draw': '和局！',
      'leaveGame': '離開遊戲？',
      'leaveGameMessage': '你的進度將不會被保存。\n確定要離開嗎？',
      'stay': '留下',
      'leave': '離開',

      // Breathing Screen
      'breathingExerciseTitle': '呼吸練習',
      'takeAMoment': '花一點時間放鬆',
      'followTheCircle': '跟著圓圈呼吸',
      'findComfortable': '找一個舒適的姿勢',
      'pressStart': '準備好就按開始',
      'startBreathing': '開始呼吸',
      'iFeelBetter': '我感覺好多了',
      'greatJob': '做得好！你很棒。',
      'inhale': '吸氣',
      'hold': '憋住',
      'exhale': '呼氣',

      // Settings Screen
      'language': '語言',
      'game': '遊戲',
      'showMoveHints': '顯示走法提示',
      'showMoveHintsDesc': '標記合法走法',
      'version': '版本',
      'aboutDesc': '專為自閉症兒童設計的情緒導向西洋棋學習',
      'help': '幫助',
      'tutorial': '教學',
      'tutorialDesc': '學習如何使用 EmoChess',
      'tutorialStep1': '1. 下棋前先確認自己的情緒',
      'tutorialStep2': '2. 下棋時表達你的感受',
      'tutorialStep3': '3. 沮喪時使用呼吸練習',
      'tutorialStep4': '4. AI 夥伴會一路陪伴你',
      'gotIt': '我知道了！',

      // Profile & Stats
      'gamesPlayed': '棋局',
      'wins': '勝場',
      'winRate': '勝率',

      // AI Companion Messages
      'aiMsgFrustrated1': '感到沮喪是正常的。要不要休息一下做個呼吸練習？',
      'aiMsgFrustrated2': '西洋棋可能很難！這就是我們學習和成長的方式。',
      'aiMsgFrustrated3': '即使最厲害的棋手也會遇到挑戰。你做得很棒！',
      'aiMsgFrustrated4': '深呼吸一下。不用著急。',
      'aiMsgFrustrated5': '記住，犯錯是學習的一部分！',
      'aiMsgCheck1': '你的國王被將軍了！慢慢想。',
      'aiMsgCheck2': '將軍！找一個方法保護你的國王。',
      'aiMsgCheck3': '不用擔心將軍。你可以的！',
      'aiMsgMistake1': '沒關係！每一步都讓我們學到東西。',
      'aiMsgMistake2': '錯誤幫助我們變得更強。',
      'aiMsgMistake3': '沒關係！看看接下來會發生什麼。',
      'aiMsgHappy1': '做得好！你表現得太棒了！',
      'aiMsgHappy2': '看到你享受遊戲讓我很開心！',
      'aiMsgHappy3': '很棒的想法！繼續保持！',
      'aiMsgHappy4': '你玩得很開心，這才是最重要的！',
      'aiMsgNeutral1': '慢慢來，不用急。',
      'aiMsgNeutral2': '你做得很好！繼續思考。',
      'aiMsgNeutral3': '每一步都是學習的機會。',
      'aiMsgNeutral4': '西洋棋是一場旅程，不是一場賽跑。',
      'chessBuddy': '棋友小夥伴',
      'imOkay': '我沒事',

      // AI & Analysis
      'aiThinking': 'AI 正在思考...',
      'emotionAnalysis': '情緒分析',
      'gameHistory': '遊戲紀錄',
      'noGamesYet': '還沒有遊戲紀錄',
      'playFirstGame': '來下第一場棋吧！',
      'gameDuration': '時長',
      'totalMoves': '步',
      'startAnalysis': '開始分析',
      'analyzing': '分析中...',
      'analysisComplete': '分析完成',
      'emotionTrend': '情緒趨勢',
      'emotionDistribution': '情緒分布',
      'analysisSummary': '摘要',
      'chatHistory': '對話紀錄',
      'moveHistory': '步數紀錄',
      'emotionEvents': '情緒事件',
      'totalChats': '對話總數',
      'initialEmotion': '初始情緒',
      'finalEmotion': '最後情緒',
      'result': '結果',
      'resultWin': '勝利',
      'resultLoss': '失敗',
      'resultDraw': '平手',
      'resultAbandoned': '已中止',
      'resultUnknown': '未知',
      'analysisNotFound': '找不到分析資料',
      'analysisNoEmotion': '目前沒有情緒資料',
      'analysisNoChat': '目前沒有對話紀錄',
      'analysisNoMoves': '目前沒有步數紀錄',
      'gameCompleted': '遊戲完成',
      'gameAbandoned': '遊戲中止',

      // Companion Interactions
      'yes': '是',
      'no': '否',
      'howIsTheGame': '這場棋下得怎麼樣？',
      'enjoyingChess': '你喜歡這場棋嗎？',
      'needHelp': '需要一個提示嗎？',
      'greatMove': '這步棋走得太好了！',
      'thinkingWell': '你想得很好！',
      'choiceGreat': '很棒！',
      'choiceOkay': '還可以',
      'choiceHard': '有點難',
      'choiceHelp': '我需要幫助',
      'responseGreat': '太好了！繼續享受吧！',
      'responseOkay': '沒關係！慢慢來。',
      'responseHard': '覺得難是正常的。你正在學習！',
      'responseHelp': '沒問題！我來給你一個小提示。',

      // Analysis Interactions
      'aiMsgCheckTrigger': '小心！你被將軍了！你能安全脫困嗎？',
      'aiMsgCaptureTrigger': '吃得好！',
      'aiMsgOpeningTrigger': '開局很穩健！你有什麼具體計畫嗎？',
      'aiMsgStrategyTrigger': '你現在的主要目標是什麼？',
      'aiMsgStrategySafety': '這步棋很大膽。你確定你的國王安全嗎？',

      // Teaching Moments
      'aiTeachPawn': '你知道嗎？兵團結起來會非常強大！',
      'aiTeachKnight': '騎士最愛跳躍！它們能到達其他棋子到不了的地方。',
      'aiTeachCastle': '王車易位可以保護你的國王。試試看？',
      'aiTeachCenter': '控制中心會給你更多選擇！試著把棋子放在那裡。',
      'aiTeachProtect': '記得保護你的棋子！好棋手總是照顧自己的團隊。',

      // Welcome
      'aiWelcome': '嗨，朋友！讓我們一起下棋吧。記住，重要的不是輸贏，而是開心！',

      'choiceAttack': '進攻',
      'choiceDefend': '防守',
      'choiceDevelop': '發展棋子',
      'choiceControl': '控制中心',

      // Game Over Dialog
      'playAgain': '再玩一次',
      'viewEmotionAnalysis': '查看情緒分析',
      'returnHome': '返回首頁',
      'youWin': '你贏了！',
      'gameOver': '遊戲結束',
      'congratsMessage': '太棒了！你下得真好！',
      'goodEffortMessage': '好棒的努力！每場比賽都讓你進步。',
      'drawMessage': '平局！雙方都下得很好。',

      // AI Fallback Messages
      'aiFallbackCheck1': '小心！你被將軍了。花點時間找到安全的一步。',
      'aiFallbackCheck2': '將軍！看看你有什麼方法保護你的國王。',
      'aiFallbackCheck3': '你的國王需要保護。你能找到出路嗎？',
      'aiFallbackCapture1': '吃得好！你下得很棒。',
      'aiFallbackCapture2': '好棋！吃子能幫助你贏得比賽。',
      'aiFallbackCapture3': '做得好！每一次吃子都很重要。',
      'aiFallbackFrustrated': '我看得出你很努力。你現在感覺如何？',
      'aiFallbackNeedHelp': '我需要幫助',
      'aiFallbackHelpResponse': '沒關係！讓我給你一個提示：看看你所有的棋子，想想哪一個可以發揮最大的作用。',
      'aiFallbackImFine': '我沒事',
      'aiFallbackFineResponse': '很高興聽到！按照你自己的節奏繼續吧。',
      'aiFallbackWantBreak': '我想休息一下',
      'aiFallbackBreakResponse': '這是個明智的選擇。休息能幫助我們思考得更好！',
      'aiFallbackTeach1': '你知道嗎？控制棋盤中心會給你更多選擇。',
      'aiFallbackTeach2': '騎士很靈活！它們可以跳過其他棋子。',
      'aiFallbackTeach3': '兵雖小但很強大。如果到達對面，可以變成任何棋子！',
      'aiFallbackTeach4': '保護你的棋子和進攻一樣重要。',
      'aiFallbackTeach5': '王車易位是保護國王的好方法。你試過嗎？',
      'aiFallbackEncourage1': '慢慢來。好棋需要仔細思考。',
      'aiFallbackEncourage2': '你做得很好！每場比賽都讓你進步。',
      'aiFallbackEncourage3': '棒！你接下來打算怎麼做？',
      'aiFallbackEncourage4': '繼續加油！西洋棋需要耐心和練習。',
      'aiFallbackHappyAmazing': '你做得太棒了！我看得出你玩得很開心。',
      'aiFallbackHappyWonderful': '很棒的思考！繼續享受吧！',
      'aiFallbackHappyGreat': '做得好！你的熱情讓人鼓舞。',
      'aiFallbackWelcome': '嗨，朋友！讓我們一起下棋吧。記住，重要的不是輸贏，而是開心和學習！',
      'aiFallbackStrategyQ': '你現在想專注於什麼？',
      'aiFallbackAttackResponse': '準備進攻！找找看哪些棋子可以威脅對手。',
      'aiFallbackDefendResponse': '想得好！穩固的防守讓贏棋更容易。',
      'aiFallbackDevelopResponse': '聰明的選擇！讓更多棋子動起來會給你更多選擇。',
      'aiFallbackControlResponse': '控制中心是關鍵！這讓你的棋子有更多活動空間。',
      'aiFallbackGenericThanks': '謝謝你的分享！繼續下棋，享受樂趣吧。',
      'aiFallbackBreakIdea': '休息是個好主意！準備好了再回來。',

      // Welcome Greeting (Interactive)
      'welcomeGreeting': '嗨！我是你的棋友小夥伴。很高興能陪你一起下棋！',
      'welcomeChoiceReady': '我準備好了！',
      'welcomeResponseReady': '太棒了！你先走白棋。慢慢來，開心就好！',
      'welcomeChoiceNervous': '有點緊張',
      'welcomeResponseNervous': '沒關係！我們慢慢來。放輕鬆，享受這場棋就好。',
      'welcomeChoiceThinking': '我還在想',
      'welcomeResponseThinking': '不急！準備好了就隨便動一個棋子吧。我會在這裡陪你！',

      // Generic Interactive Choices
      'choiceThanks': '謝謝！',
      'responseThanks': '不客氣！繼續專注。',
      'choiceCool': '酷！',
      'responseCool': '對吧？西洋棋很有趣。',
      'choiceInteresting': '很有趣',
      'responseInteresting': '我也這麼覺得！學習新事物很好玩。',
      'choiceGoodPoint': '說得好',
      'responseGoodPoint': '很高興這對你有幫助！看看接下來會發生什麼。',
      'choiceGotIt': '知道了',
      'responseGotIt': '太好了！試著在下一步運用這些知識。',
    },
  };

  String get(String key) {
    final langCode = locale.languageCode;
    return _localizedStrings[langCode]?[key] ??
        _localizedStrings['en']?[key] ??
        key;
  }

  // Convenience getters
  String get appName => get('appName');
  String get appTagline => get('appTagline');
  String get appDescription => get('appDescription');
  String get playChess => get('playChess');
  String get breathingExercise => get('breathingExercise');
  String get settings => get('settings');
  String get howAreYouFeeling => get('howAreYouFeeling');
  String get beforeWeStart => get('beforeWeStart');
  String get noWrongAnswer => get('noWrongAnswer');
  String get letsPlay => get('letsPlay');
  String get happy => get('happy');
  String get neutral => get('neutral');
  String get frustrated => get('frustrated');
  String get howDoYouFeel => get('howDoYouFeel');
  String get emoChess => get('emoChess');
  String get undoMove => get('undoMove');
  String get takeABreath => get('takeABreath');
  String get whiteTurn => get('whiteTurn');
  String get blackTurn => get('blackTurn');
  String get check => get('check');
  String get whiteWins => get('whiteWins');
  String get blackWins => get('blackWins');
  String get draw => get('draw');
  String get leaveGame => get('leaveGame');
  String get leaveGameMessage => get('leaveGameMessage');
  String get stay => get('stay');
  String get leave => get('leave');
  String get breathingExerciseTitle => get('breathingExerciseTitle');
  String get takeAMoment => get('takeAMoment');
  String get followTheCircle => get('followTheCircle');
  String get findComfortable => get('findComfortable');
  String get pressStart => get('pressStart');
  String get startBreathing => get('startBreathing');
  String get iFeelBetter => get('iFeelBetter');
  String get greatJob => get('greatJob');
  String get inhale => get('inhale');
  String get hold => get('hold');
  String get exhale => get('exhale');
  String get language => get('language');
  String get accessibility => get('accessibility');
  String get reducedMotion => get('reducedMotion');
  String get reducedMotionDesc => get('reducedMotionDesc');
  String get highContrast => get('highContrast');
  String get highContrastDesc => get('highContrastDesc');
  String get game => get('game');
  String get showMoveHints => get('showMoveHints');
  String get showMoveHintsDesc => get('showMoveHintsDesc');
  String get soundEffects => get('soundEffects');
  String get soundEffectsDesc => get('soundEffectsDesc');
  String get breathingDuration => get('breathingDuration');
  String get version => get('version');
  String get aboutDesc => get('aboutDesc');
  String get chessBuddy => get('chessBuddy');
  String get imOkay => get('imOkay');
  String get help => get('help');
  String get tutorial => get('tutorial');
  String get tutorialDesc => get('tutorialDesc');
  String get tutorialStep1 => get('tutorialStep1');
  String get tutorialStep2 => get('tutorialStep2');
  String get tutorialStep3 => get('tutorialStep3');
  String get tutorialStep4 => get('tutorialStep4');
  String get gotIt => get('gotIt');

  // New Analysis Keys
  String get aiMsgCheckTrigger => get('aiMsgCheckTrigger');
  String get aiMsgCaptureTrigger => get('aiMsgCaptureTrigger');
  String get aiMsgOpeningTrigger => get('aiMsgOpeningTrigger');
  String get aiMsgStrategyTrigger => get('aiMsgStrategyTrigger');
  String get aiMsgStrategySafety => get('aiMsgStrategySafety');

  String get choiceAttack => get('choiceAttack');
  String get choiceDefend => get('choiceDefend');
  String get choiceDevelop => get('choiceDevelop');
  String get choiceControl => get('choiceControl');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
