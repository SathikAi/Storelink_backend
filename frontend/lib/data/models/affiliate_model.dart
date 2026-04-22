class AffiliateStats {
  final String referralCode;
  final String referralLink;
  final int totalReferrals;
  final int rewardedReferrals;
  final int pendingReferrals;
  final int rewardDaysPerReferral;
  final int totalDaysEarned;

  const AffiliateStats({
    required this.referralCode,
    required this.referralLink,
    required this.totalReferrals,
    required this.rewardedReferrals,
    required this.pendingReferrals,
    required this.rewardDaysPerReferral,
    required this.totalDaysEarned,
  });

  factory AffiliateStats.fromJson(Map<String, dynamic> j) => AffiliateStats(
        referralCode: j['referral_code'] as String,
        referralLink: j['referral_link'] as String,
        totalReferrals: j['total_referrals'] as int,
        rewardedReferrals: j['rewarded_referrals'] as int,
        pendingReferrals: j['pending_referrals'] as int,
        rewardDaysPerReferral: j['reward_days_per_referral'] as int,
        totalDaysEarned: j['total_days_earned'] as int,
      );
}
