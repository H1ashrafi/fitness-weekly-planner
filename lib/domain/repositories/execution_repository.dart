import '../../core/time/week_stamp.dart';
import '../entities/set_execution.dart';
import '../entities/set_outcome.dart';

abstract interface class ExecutionRepository {
  Future<Map<SetExecutionKey, SetOutcome>> outcomesForWeek(WeekStamp week);

  Future<void> record(SetExecution execution);

  Future<void> clearExercise(String exerciseId, WeekStamp week);

  Future<List<SetExecution>> recordedBetween(DateTime start, DateTime end);

  Future<List<WeekStamp>> weeksWithActivity();
}
