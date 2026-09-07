import 'package:equatable/equatable.dart';

abstract class ReferralEvent extends Equatable {
  const ReferralEvent();

  @override
  List<Object> get props => [];
}

class LoadReferralStats extends ReferralEvent {}

class ShareInviteLink extends ReferralEvent {}
