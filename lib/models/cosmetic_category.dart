/// Categorías de cosméticos, en el orden del mockup del Vestuario.
enum CosmeticCategory {
  shirt('Camisa', 'Camisa', 'Aún no tienes ninguna camisa'),
  pants('Pantalón', 'Pantalón', 'Aún no tienes ningún pantalón'),
  shoes('Zapatos', 'Zapatos', 'Aún no tienes zapatos de fiesta'),
  hair('Cabello', 'Cabello', 'Aún no tienes cabellos'),
  nose('Nariz', 'Nariz', 'Aún no tienes ninguna nariz'),
  eyes('Ojos', 'Ojo', 'Aún no tienes ojos'),
  mouth('Boca', 'Boca', 'Aún no tienes ninguna boca');

  const CosmeticCategory(this.label, this.itemName, this.emptyMessage);

  /// Texto de la pestaña.
  final String label;

  /// Nombre en singular, para los cosméticos ("Ojo 1").
  final String itemName;

  /// Mensaje que se muestra cuando el jugador no tiene ningún cosmético
  /// de esta categoría.
  final String emptyMessage;
}