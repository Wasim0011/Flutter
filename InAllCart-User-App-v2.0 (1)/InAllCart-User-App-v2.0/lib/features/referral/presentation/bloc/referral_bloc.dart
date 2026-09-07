import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_referral_stats.dart';
import '../../domain/usecases/get_invite_link.dart';
import 'referral_event.dart';
import 'referral_state.dart';

class ReferralBloc extends Bloc<ReferralEvent, ReferralState> {
  final GetReferralStats getReferralStats;
  final GetInviteLink getInviteLink;

  ReferralBloc({
    required this.getReferralStats,
    required this.getInviteLink,
  }) : super(ReferralInitial()) {
    on<LoadReferralStats>(_onLoadReferralStats);
    on<ShareInviteLink>(_onShareInviteLink);
  }

  Future<void> _onLoadReferralStats(
    LoadReferralStats event,
    Emitter<ReferralState> emit,
  ) async {
    emit(ReferralLoading());
    try {
      final stats = await getReferralStats();
      emit(ReferralLoaded(stats));
    } catch (e) {
      emit(ReferralError(e.toString()));
    }
  }

  Future<void> _onShareInviteLink(
    ShareInviteLink event,
    Emitter<ReferralState> emit,
  ) async {
    try {
      final link = await getInviteLink();
      emit(InviteLinkShared(link));
      // Re-emit loaded state if we have stats cached
      if (state is ReferralLoaded) {
        emit(ReferralLoaded((state as ReferralLoaded).stats));
      }
    } catch (e) {
      emit(ReferralError(e.toString()));
    }
  }
}
