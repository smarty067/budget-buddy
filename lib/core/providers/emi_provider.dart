import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emi_calculation.dart';
import '../services/emi_service.dart';
import 'auth_provider.dart';

final emiCalculationsProvider = FutureProvider.autoDispose<List<EmiCalculation>>((ref) async {
  final isGuest = ref.watch(isGuestProvider);
  return EmiService.getCalculations(isGuest: isGuest);
});

class CurrentEmiState {
  final double loanAmount;
  final double interestRate;
  final int tenureYears;
  final EmiCalculation calculation;

  CurrentEmiState({
    required this.loanAmount,
    required this.interestRate,
    required this.tenureYears,
    required this.calculation,
  });

  CurrentEmiState copyWith({
    double? loanAmount,
    double? interestRate,
    int? tenureYears,
  }) {
    final newAmount = loanAmount ?? this.loanAmount;
    final newRate = interestRate ?? this.interestRate;
    final newTenure = tenureYears ?? this.tenureYears;

    return CurrentEmiState(
      loanAmount: newAmount,
      interestRate: newRate,
      tenureYears: newTenure,
      calculation: EmiCalculation.compute(
        loanAmount: newAmount,
        interestRate: newRate,
        tenureYears: newTenure,
      ),
    );
  }
}

class CurrentEmiNotifier extends StateNotifier<CurrentEmiState> {
  CurrentEmiNotifier()
      : super(
          CurrentEmiState(
            loanAmount: 500000,
            interestRate: 9.5,
            tenureYears: 5,
            calculation: EmiCalculation.compute(
              loanAmount: 500000,
              interestRate: 9.5,
              tenureYears: 5,
            ),
          ),
        );

  void updateAmount(double amount) {
    state = state.copyWith(loanAmount: amount);
  }

  void updateInterestRate(double rate) {
    state = state.copyWith(interestRate: rate);
  }

  void updateTenure(int years) {
    state = state.copyWith(tenureYears: years);
  }

  void setCalculation(EmiCalculation calc) {
    state = CurrentEmiState(
      loanAmount: calc.loanAmount,
      interestRate: calc.interestRate,
      tenureYears: calc.tenureYears,
      calculation: calc,
    );
  }
}

final currentEmiProvider =
    StateNotifierProvider<CurrentEmiNotifier, CurrentEmiState>((ref) {
  return CurrentEmiNotifier();
});
