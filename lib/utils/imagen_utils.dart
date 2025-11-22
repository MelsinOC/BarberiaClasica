/// Utilidades para manejo de imágenes de servicios
class ImagenUtils {
  /// Obtener URL de imagen según el nombre del servicio
  static String getImagenServicio(String nombre) {
    final nombreLower = nombre.toLowerCase();

    // Servicios de corte
    if (nombreLower.contains('corte clásico')) {
      return 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400&h=300&fit=crop&crop=center';
    } else if (nombreLower.contains('fade moderno') ||
        nombreLower.contains('fade')) {
      return 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400&h=300&fit=crop&crop=center';
    } else if (nombreLower.contains('undercut')) {
      return 'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=400&h=300&fit=crop&crop=center';
    }
    // Servicios de barba y afeitado
    else if (nombreLower.contains('afeitado clásico') ||
        nombreLower.contains('afeitado')) {
      return 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400&h=300&fit=crop&crop=center';
    } else if (nombreLower.contains('barba') ||
        (nombreLower.contains('corte') && nombreLower.contains('barba'))) {
      return 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400&h=300&fit=crop&crop=center';
    }
    // Servicios de cuidado
    else if (nombreLower.contains('tratamiento') ||
        nombreLower.contains('masaje')) {
      return 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&h=300&fit=crop&crop=center';
    } else if (nombreLower.contains('limpieza facial') ||
        nombreLower.contains('facial')) {
      return 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=400&h=300&fit=crop&crop=center';
    }
    // Imagen por defecto
    return 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400&h=300&fit=crop&crop=center';
  }
}
