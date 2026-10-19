import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_language.dart';

final translationsProvider = Provider<Translations>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return Translations(lang);
});

class Translations {
  final AppLanguage language;

  const Translations(this.language);

  bool get isVietnamese => language == AppLanguage.vi;

  // General & Nav (4 Tabs)
  String get appName => 'QuitCapping';
  String get appTagline => isVietnamese
      ? 'Bớt bốc phét. Đưa bằng chứng thật.'
      : 'Stop capping. Provide real proof.';
  String get tasks => isVietnamese ? 'Nhiệm vụ' : 'Tasks';
  String get goals => isVietnamese ? 'Mục tiêu' : 'Goals';
  String get roadmap => isVietnamese ? 'Lộ trình' : 'Roadmap';
  String get peerReview => isVietnamese ? 'Đánh giá chéo' : 'Peer Review';
  String get profile => isVietnamese ? 'Cá nhân' : 'Profile';
  String get settings => isVietnamese ? 'Cài đặt' : 'Settings';
  String get languageTitle => isVietnamese ? 'Ngôn ngữ' : 'Language';
  String get cancel => isVietnamese ? 'Hủy' : 'Cancel';
  String get confirm => isVietnamese ? 'Xác nhận' : 'Confirm';
  String get logOut => isVietnamese ? 'Đăng xuất' : 'Log Out';
  String get logOutConfirm => isVietnamese
      ? 'Bạn có chắc chắn muốn đăng xuất khỏi QuitCapping?'
      : 'Are you sure you want to log out of QuitCapping?';

  // Tab 1: Today's Tasks
  String get todayTasks => isVietnamese ? 'Nhiệm vụ hôm nay' : "Today's Tasks";
  String get todayTasksSubtitle => isVietnamese
      ? '{completed}/{total} nhiệm vụ hôm nay'
      : '{completed}/{total} tasks today';
  String get noTasksToday => isVietnamese
      ? 'Hôm nay chưa có nhiệm vụ nào'
      : 'No tasks for today';
  String get noTasksTodayDesc => isVietnamese
      ? 'Bạn chưa có mục tiêu nào đang hoạt động. Hãy tạo hoặc chọn mục tiêu để bắt đầu ngay!'
      : 'You have no active goals. Create or choose a goal to get started!';
  String get goToGoals => isVietnamese ? 'ĐẾN MỤC TIÊU' : 'GO TO GOALS';
  String get activeGoal => isVietnamese ? 'Mục tiêu đang chọn' : 'Active Goal';
  String get switchGoal => isVietnamese ? 'Đổi mục tiêu' : 'Switch Goal';
  String get openTask => isVietnamese ? 'Mở' : 'Open';
  String get searchByDate => isVietnamese ? 'Tìm ngày lịch sử' : 'Search by date';
  String get enterDatePrompt => isVietnamese
      ? 'Nhập hoặc chọn ngày trong lịch sử (dd/MM/yyyy):'
      : 'Enter or pick a date in history (dd/MM/yyyy):';
  String get selectDate => isVietnamese ? 'Chọn ngày' : 'Select Date';
  String get invalidDate => isVietnamese ? 'Ngày không hợp lệ' : 'Invalid date format';
  String get taskDetail => isVietnamese ? 'Chi tiết nhiệm vụ' : 'Task Details';
  String get taskDescription => isVietnamese ? 'Mô tả nhiệm vụ' : 'Task Description';
  String get submittedEvidence => isVietnamese ? 'Bằng chứng đã nộp' : 'Submitted Evidence';
  String get submitEvidenceNow => isVietnamese ? 'Nộp ảnh bằng chứng' : 'Submit Photo Evidence';
  String get todayLabel => isVietnamese ? 'Hôm nay' : 'Today';
  String get noTasksForThisDay => isVietnamese
      ? 'Bạn không có việc cần làm vào ngày này'
      : 'You have no tasks to do on this day';
  String get noTasksForThisDayDesc => isVietnamese
      ? 'Không có nhiệm vụ nào được ghi nhận cho ngày này. Hãy chọn ngày khác hoặc quay lại hôm nay.'
      : 'No tasks recorded for this date. Select another date or return to today.';
  String get backToToday => isVietnamese ? 'Về ngày hôm nay' : 'Back to Today';
  String get tasksCompletedOnDate => isVietnamese
      ? '{completed}/{total} nhiệm vụ hoàn thành'
      : '{completed}/{total} tasks completed';
  String get noTasksOnDate => isVietnamese
      ? 'Không có việc cần làm'
      : 'No tasks to do';
  String get tasksForDateTitle => isVietnamese
      ? 'Nhiệm vụ ngày {date}'
      : 'Tasks for {date}';
  String get dailyTasksTitle => isVietnamese ? 'Nhiệm vụ hàng ngày' : 'Daily Tasks';
  String get editTask => isVietnamese ? 'Sửa nhiệm vụ' : 'Edit Task';
  String get taskTitle => isVietnamese ? 'Tên nhiệm vụ' : 'Task Title';
  String get taskTitleHint => isVietnamese ? 'Nhập tên nhiệm vụ' : 'Enter task title';
  String get taskDescHint => isVietnamese ? 'Nhập mô tả nhiệm vụ (tùy chọn)' : 'Enter task description (optional)';
  String get evidenceRequirementHint => isVietnamese
      ? 'Yêu cầu bằng chứng ảnh (VD: Chụp màn hình, ảnh tập gym...)'
      : 'Evidence photo requirement (e.g. Screenshot, gym photo...)';
  String get save => isVietnamese ? 'Lưu' : 'Save';
  String get taskUpdatedSuccess => isVietnamese ? 'Cập nhật nhiệm vụ thành công!' : 'Task updated successfully!';
  String get addTask => isVietnamese ? 'Thêm nhiệm vụ' : 'Add Task';
  String get createCustomTaskTitle => isVietnamese ? 'Thêm nhiệm vụ cho ngày' : 'Add Task for Date';
  String get taskCreatedSuccess => isVietnamese ? 'Đã thêm nhiệm vụ mới!' : 'Task created successfully!';
  String get points => isVietnamese ? 'Điểm thưởng' : 'Reward Points';
  String pointsCount(int count) => isVietnamese ? '$count điểm' : '$count pts';
  String get goalCreationCostNotice => isVietnamese
      ? 'Tạo mục tiêu tiêu hao 500 điểm'
      : 'Creating a goal costs 500 points';
  String get notEnoughPoints => isVietnamese
      ? 'Bạn không đủ 500 điểm để tạo mục tiêu'
      : 'You do not have enough 500 points to create a goal';
  String currentBalance(int points) => isVietnamese ? 'Số dư: $points điểm' : 'Balance: $points pts';
  String get pointsEarnedInfo => isVietnamese
      ? 'Nộp bằng chứng: +10đ • Duyệt: +10đ • Chấm bài: +5đ'
      : 'Proof: +10pts • Approved: +10pts • Review: +5pts';

  // Tab 2: Goals Management
  String get yourGoals => isVietnamese ? 'Danh sách mục tiêu' : 'Your Goals';
  String get allGoals => isVietnamese ? 'Tất cả mục tiêu' : 'All Goals';
  String get activeTag => isVietnamese ? 'ĐANG HOẠT ĐỘNG' : 'ACTIVE';
  String get completedTag => isVietnamese ? 'ĐÃ HOÀN THÀNH' : 'COMPLETED';
  String get viewRoadmap => isVietnamese ? 'Xem lộ trình chi tiết' : 'View Full Roadmap';
  String get noGoalsYet => isVietnamese ? 'Chưa có mục tiêu nào' : 'No goals yet';
  String get noGoalsYetDesc => isVietnamese
      ? 'Nhấn "+ Tạo mục tiêu AI" để Google Gemini lập kế hoạch micro-tasks cho bạn!'
      : 'Tap "+ New AI Goal" to let Google Gemini generate your micro-tasks roadmap!';
  String get roadmapDetailTitle => isVietnamese ? 'Lộ trình chi tiết' : 'Roadmap Detail';
  String get dayProgression => isVietnamese
      ? 'Ngày {current}/{total} • {percent}%'
      : 'Day {current}/{total} • {percent}%';

  // Auth Screen
  String get email => 'Email';
  String get password => isVietnamese ? 'Mật khẩu' : 'Password';
  String get displayName => isVietnamese ? 'Tên hiển thị' : 'Display Name';
  String get logIn => isVietnamese ? 'ĐĂNG NHẬP' : 'LOG IN';
  String get signUp => isVietnamese ? 'Đăng ký' : 'Sign Up';
  String get createAccount => isVietnamese ? 'TẠO TÀI KHOẢN' : 'CREATE ACCOUNT';
  String get joinQuitCapping => isVietnamese ? 'Gia nhập QuitCapping' : 'Join QuitCapping';
  String get joinSubtitle => isVietnamese
      ? 'Lập lộ trình AI, nộp ảnh bằng chứng và cùng nhau loại bỏ thói quen trì hoãn.'
      : 'Lock in daily roadmaps, submit photo proof, and hold each other accountable.';
  String get dontHaveAccount => isVietnamese ? 'Chưa có tài khoản? ' : "Don't have an account? ";
  String get alreadyHaveAccount => isVietnamese ? 'Đã có tài khoản? ' : 'Already have an account? ';
  String get enterEmailPrompt => isVietnamese ? 'Vui lòng nhập email' : 'Please enter your email';
  String get validEmailPrompt => isVietnamese ? 'Email không hợp lệ' : 'Enter a valid email address';
  String get enterPasswordPrompt => isVietnamese ? 'Vui lòng nhập mật khẩu' : 'Please enter your password';
  String get passwordLengthPrompt => isVietnamese ? 'Mật khẩu phải từ 6 ký tự' : 'Password must be at least 6 characters';
  String get enterNamePrompt => isVietnamese ? 'Vui lòng nhập tên hiển thị' : 'Please enter your name';

  // Roadmap & Tasks
  String get dailyRoadmap => isVietnamese ? 'Lộ trình hàng ngày' : 'Daily Roadmap';
  String get newAiGoal => isVietnamese ? 'Tạo mục tiêu AI' : 'New AI Goal';
  String get noActiveRoadmap => isVietnamese ? 'Chưa có lộ trình nào' : 'No Active Roadmap Yet';
  String get noActiveRoadmapDesc => isVietnamese
      ? 'Tạo mục tiêu của bạn để Google Gemini AI lên kế hoạch micro-tasks và yêu cầu ảnh bằng chứng mỗi ngày.'
      : 'Create a target goal and let Google Gemini AI build your daily micro-tasks and evidence prompts.';
  String get createAiGoalBtn => isVietnamese ? 'TẠO MỤC TIÊU AI' : 'CREATE AI GOAL';
  String get dayXOfY => isVietnamese ? 'Ngày {x} / {y}' : 'Day {x} of {y}';
  String get microTasksForDay => isVietnamese ? 'Nhiệm vụ Ngày {day}' : 'Day {day} Micro-Tasks';
  String get completedStats => isVietnamese ? '{completed}/{total} Hoàn thành' : '{completed}/{total} Completed';
  String get proofRequired => isVietnamese ? 'Bằng chứng: ' : 'Proof: ';
  String get submitProof => isVietnamese ? 'NỘP BẰNG CHỨNG' : 'SUBMIT PROOF';
  String get retryProof => isVietnamese ? 'NỘP LẠI BẰNG CHỨNG' : 'RETRY PROOF';
  String get pendingProofBadge => isVietnamese ? 'CHỜ NỘP ẢNH' : 'PENDING PROOF';
  String get lockedBadge => isVietnamese ? 'ĐANG KHÓA' : 'LOCKED';
  String get inQueueBadge => isVietnamese ? 'ĐANG DUYỆT' : 'IN QUEUE';
  String get approvedBadge => isVietnamese ? 'ĐÃ ĐẠT' : 'APPROVED';
  String get rejectedBadge => isVietnamese ? 'BỊ TỪ CHỐI' : 'REJECTED';
  String get lockedNotice => isVietnamese
      ? 'Đang khóa: Hãy đánh giá 5 bài của người khác hôm nay để mở khóa vào hàng đợi.'
      : 'Locked: Review 5 peer submissions today to release to queue.';
  String inQueueNotice(int up, int down) => isVietnamese
      ? 'Đang chấm điểm: $up đồng ý, $down từ chối (cần 3 phiếu)'
      : 'In Review: $up approves, $down rejects (3 needed)';

  // Create Goal Screen
  String get newAiGoalTitle => isVietnamese ? 'Mục tiêu AI Chống Trì Hoãn' : 'New AI Accountability Goal';
  String get poweredByGemini => isVietnamese ? 'Ứng dụng Google Gemini AI' : 'Powered by Google Gemini';
  String get geminiDesc => isVietnamese
      ? 'Gemini tạo 3-4 nhiệm vụ nhỏ mỗi ngày với yêu cầu chụp ảnh bằng chứng nghiêm ngặt.'
      : 'Gemini generates daily micro-tasks with strict photo evidence rules.';
  String get targetGoalQuestion => isVietnamese ? 'Mục tiêu của bạn là gì?' : 'What is your target goal?';
  String get targetGoalHint => isVietnamese
      ? 'VD: Luyện tập LeetCode 14 ngày, Chạy bộ 10km, Học Flutter'
      : 'e.g. Master Flutter & Riverpod, Run 10km marathon';
  String get category => isVietnamese ? 'Danh mục' : 'Category';
  String get currentSkillLevel => isVietnamese ? 'Trình độ hiện tại' : 'Current Skill Level';
  String get targetDuration => isVietnamese ? 'Thời lượng mục tiêu' : 'Target Duration';
  String get daysSuffix => isVietnamese ? 'Ngày' : 'Days';
  String get generateBtn => isVietnamese ? 'TẠO LỘ TRÌNH VỚI AI' : 'GENERATE AI ROADMAP';
  String get generatingText => isVietnamese ? 'Gemini AI đang tạo lộ trình...' : 'Generating AI Roadmap...';

  // Skill levels & Categories
  String skillLevelName(String level) {
    if (!isVietnamese) return level;
    switch (level) {
      case 'Beginner':
        return 'Mới bắt đầu';
      case 'Intermediate':
        return 'Trung cấp';
      case 'Advanced':
        return 'Nâng cao';
      default:
        return level;
    }
  }

  String categoryName(String cat) {
    if (!isVietnamese) return cat;
    switch (cat) {
      case 'Coding':
        return 'Lập trình';
      case 'Fitness':
        return 'Thể thao/Gym';
      case 'Academics':
        return 'Học tập';
      case 'Productivity':
        return 'Năng suất';
      case 'Career':
        return 'Sự nghiệp';
      default:
        return cat;
    }
  }

  // Submit Proof Modal
  String get proofRequirementHeader => isVietnamese
      ? 'YÊU CẦU BẰNG CHỨNG CỘNG ĐỒNG'
      : 'COMMUNITY EVIDENCE REQUIREMENT';
  String get noPhotoSelected => isVietnamese
      ? 'Chưa chọn ảnh bằng chứng nào'
      : 'No evidence photo selected yet';
  String get camera => isVietnamese ? 'Máy ảnh' : 'Camera';
  String get gallery => isVietnamese ? 'Thư viện' : 'Gallery';
  String get demoPhoto => isVietnamese ? 'Dùng ảnh mẫu (Demo)' : 'Use Demo Photo';
  String get submitEvidenceBtn => isVietnamese
      ? 'GỬI BẰNG CHỨNG ĐỂ ĐÁNH GIÁ'
      : 'SUBMIT EVIDENCE FOR REVIEW';
  String get proofInQueueTitle => isVietnamese ? 'Bằng chứng đã vào hàng đợi!' : 'Proof In Queue!';
  String get giveToGetLockedTitle => isVietnamese ? 'Đã khóa theo luật Give-to-Get' : 'Give-to-Get Locked';
  String get gotIt => isVietnamese ? 'ĐÃ HIỂU' : 'GOT IT';

  // Peer Review & Give-to-Get
  String get communityPeerReview => isVietnamese ? 'Đánh giá Chéo Cộng đồng' : 'Community Peer Review';
  String get giveToGetUnlockedHeader => isVietnamese
      ? 'Đã mở khóa Give-to-Get! 🎉'
      : 'Give-to-Get Quota Unlocked! 🎉';
  String get giveToGetEngineTitle => isVietnamese
      ? 'Cơ chế Give-to-Get'
      : 'Give-to-Get Engine';
  String get reviewsTodayFormat => isVietnamese ? '{done} / {target} Lượt đánh giá hôm nay' : '{done} / {target} Reviews Today';
  String get quotaUnlockedDesc => isVietnamese
      ? 'Ảnh bằng chứng của bạn đang hoạt động trong hàng đợi cộng đồng để nhận bình chọn!'
      : 'Your photo proofs are active in the global queue receiving peer votes!';
  String quotaNeededDesc(int remaining) => isVietnamese
      ? 'Hãy đánh giá thêm $remaining bài để ảnh nộp của bạn được đưa vào hàng đợi cộng đồng.'
      : 'Evaluate $remaining more proofs to release your own proofs to the community.';
  String get blindReviewWatermark => isVietnamese
      ? 'Đánh giá ẩn danh • Giấu danh tính'
      : 'Blind Review • Identity Hidden';
  String get verifyCriteriaPrefix => isVietnamese ? 'Kiểm tra: ' : 'Verify: ';
  String get approveStamp => isVietnamese ? 'ĐẠT' : 'APPROVE';
  String get rejectStamp => isVietnamese ? 'TỪ CHỐI' : 'REJECT';
  String get queueCaughtUpTitle => isVietnamese ? 'Hàng đợi đã hết!' : 'Queue Caught Up!';
  String get queueCaughtUpDesc => isVietnamese
      ? 'Bạn đã đánh giá hết các bài nộp hiện có hoặc chưa có bài mới. Tuyệt vời!'
      : 'You have reviewed all available community submissions or there are no submissions waiting. Great job staying accountable!';
  String get refreshQueue => isVietnamese ? 'LÀM MỚI HÀNG ĐỢI' : 'REFRESH QUEUE';
  String get quotaMetCelebrationTitle => isVietnamese ? 'Đạt Hạn Mức Give-to-Get! 🎉' : 'Give-to-Get Quota Met! 🎉';
  String quotaMetCelebrationBody(int count) => isVietnamese
      ? 'Bạn đã hoàn thành 5 lượt đánh giá hôm nay!\n\n$count bài nộp của bạn đã được mở khóa và đưa vào hàng đợi chấm điểm của cộng đồng.'
      : 'You completed your 5 peer reviews for today!\n\n$count of your pending task submissions have been unlocked and entered the community review queue.';
  String get letsGo => isVietnamese ? 'QUÁ ĐỈNH!' : 'LETS GO!';
  String get yourSubmissionTag => isVietnamese ? '🏷️ Bài nộp của bạn' : '🏷️ Your Submission';
  String get yourSubmissionSubtitle => isVietnamese
      ? 'Đang trong hàng đợi chờ cộng đồng đánh giá'
      : 'In community queue awaiting peer votes';
  String get cannotReviewOwnSubmission => isVietnamese
      ? 'Bạn không thể tự đánh giá bài nộp của chính mình'
      : 'You cannot review your own submission';
  String get skipOwnSubmissionButton => isVietnamese ? 'Bỏ qua bài này' : 'Skip This Task';
  String get lowQueueBypassNotice => isVietnamese
      ? 'Hàng đợi có dưới 5 bài, bài nộp được đưa thẳng vào hàng đợi.'
      : 'Queue has < 5 tasks, proofs enter queue directly.';
  String get antiCheatRulesTitle => isVietnamese ? 'Luật Chống Gian Lận & Đánh Giá' : 'Anti-Cheat & Review Rules';
  String get rulesContent => isVietnamese
      ? '1. Hạn mức Give-to-Get:\nBạn phải đánh giá ít nhất 5 bài nộp mỗi ngày trước khi bài của bạn được cộng đồng chấm.\n\n'
        '2. Đồng thuận 3 phiếu:\n5 người ngẫu nhiên đánh giá mỗi bài. 3 phiếu Đạt = Hoàn thành task. 3 phiếu Từ chối = Phải nộp lại.\n\n'
        '3. Đánh giá ẩn danh:\nDanh tính tác giả được giấu kín hoàn toàn để tránh thiên vị.'
      : '1. Give-to-Get Quota:\nYou must review at least 5 submissions each day before your own submissions enter the evaluation queue.\n\n'
        '2. 3-Vote Consensus:\n5 random users review each submission. 3 Approves marks it completed. 3 Rejects requires a retry.\n\n'
        '3. Blind Review:\nAuthor identity is completely hidden to prevent bias or favoritism.';
  String get understood => isVietnamese ? 'ĐÃ RÕ' : 'UNDERSTOOD';

  // Profile Screen
  String get streakTitle => isVietnamese ? 'CHUỖI NGÀY' : 'STREAK';
  String get daysStreak => isVietnamese ? '{count} Ngày' : '{count} Days';
  String get zeroCapNotice => isVietnamese ? 'Cam kết không bốc phét' : 'Zero cap allowed';
  String get quotaTitle => isVietnamese ? 'HẠN MỨC' : 'QUOTA';
  String get unlockedInQueue => isVietnamese ? 'Đã mở khóa hàng đợi' : 'Unlocked in queue';
  String get lockedUntil5 => isVietnamese ? 'Khóa (cần 5 lượt)' : 'Locked until 5';
  String get currentRoadmap => isVietnamese ? 'Lộ trình hiện tại' : 'Current Roadmap';
  String get noActiveGoalProfile => isVietnamese
      ? 'Chưa có mục tiêu. Hãy qua tab Lộ trình để tạo với Gemini AI.'
      : 'No active goal. Head to the Roadmap tab to generate one with Gemini AI.';
  String get antiCheatSummary => isVietnamese
      ? '• Chỉ mở khóa bằng chứng khi hoàn thành 5 lượt chấm chéo mỗi ngày (UTC).\n'
        '• 5 người dùng ngẫu nhiên chấm điểm ẩn danh.\n'
        '• 3 phiếu đồng ý để hoàn thành; 3 phiếu từ chối yêu cầu nộp lại.'
      : '• Proofs are only evaluated after 5 peer reviews are completed each UTC day.\n'
        '• 5 distinct peers evaluate each submission blindly.\n'
        '• 3 approves verify completion; 3 rejects demand a retry.';
}
