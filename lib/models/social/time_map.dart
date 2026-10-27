/// Las fechas de amigos y chat se guardan en milisegundos (como en `Room`),
/// así los modelos no dependen del tipo `Timestamp` de Firestore.
class TimeMap {
  const TimeMap._();

  static int write(DateTime time) => time.millisecondsSinceEpoch;

  static DateTime? read(Object? value) {
    if (value is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
}
