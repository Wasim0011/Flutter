import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import '../../features/app_content/presentation/bloc/app_content_bloc.dart';

class AnimatedSearchText extends StatefulWidget {
  const AnimatedSearchText({super.key});

  @override
  State<AnimatedSearchText> createState() => _AnimatedSearchTextState();
}

class _AnimatedSearchTextState extends State<AnimatedSearchText> {
  int _currentIndex = 0;
  Timer? _timer;
  final List<String> _initialSearchTerms = ['Milk', 'Bread', 'Eggs', 'Vegetables'];
  List<String> _searchTerms = [];

  @override
  void initState() {
    super.initState();
    _searchTerms = List.from(_initialSearchTerms);
    _startTimer();
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _searchTerms.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _searchTerms.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppContentBloc, AppContentState>(
      listenWhen: (previous, current) => current is AppContentLoaded,
      listener: (context, state) {
        if (state is AppContentLoaded) {
          final Set<String> names = {};
          for (var content in state.contents) {
            if (content.products != null) {
              for (var product in content.products!) {
                names.add(product.name);
              }
            }
          }
          if (names.isNotEmpty) {
            final newTerms = names.toList();
            // Only update if terms actually changed
            if (newTerms.length != _searchTerms.length || !newTerms.every((e) => _searchTerms.contains(e))) {
               setState(() {
                 _searchTerms = newTerms;
                 // Reset index if it's out of bounds after update
                 if (_currentIndex >= _searchTerms.length) {
                   _currentIndex = 0;
                 }
               });
            }
          }
        }
      },
      child: BlocBuilder<AppContentBloc, AppContentState>(
        buildWhen: (previous, current) => current is AppContentLoaded,
        builder: (context, state) {
          final terms = _searchTerms.isNotEmpty ? _searchTerms : _initialSearchTerms;
          final displayIndex = _currentIndex < terms.length ? _currentIndex : 0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Search "',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(0.0, 0.5), 
                      end: Offset.zero
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

                    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
                        .animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

                    return FadeTransition(
                      opacity: fadeAnimation,
                      child: SlideTransition(
                        position: child.key == ValueKey<int>(displayIndex) 
                            ? offsetAnimation 
                            : const AlwaysStoppedAnimation(Offset.zero),
                        child: child,
                      ),
                    );
                  },
                  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: Text(
                    '${terms[displayIndex].trim().split(' ').take(2).join(' ')}"',
                    key: ValueKey<int>(displayIndex),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
