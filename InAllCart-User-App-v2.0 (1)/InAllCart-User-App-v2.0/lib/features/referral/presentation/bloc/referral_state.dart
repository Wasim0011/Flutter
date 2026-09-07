import 'package:equatable/equatable.dart';
import '../../domain/entities/referral_stats.dart';

abstract class ReferralState extends Equatable {
  const ReferralState();

  @override
  List<Object?> get props => [];
}

class ReferralInitial extends ReferralState {}

class ReferralLoading extends ReferralState {}

class ReferralLoaded extends ReferralState {
  final ReferralStats stats;

  const ReferralLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class ReferralError extends ReferralState {
  final String message;

  const ReferralError(this.message);

  @override
  List<Object?> get props => [message];
}

class InviteLinkShared extends ReferralState {
  final String link;

  const InviteLinkShared(this.link);

  @override
  List<Object?> get props => [link];
}
