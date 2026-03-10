// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'iSuite - Administrador de Archivos Owlfiles';

  @override
  String get wifiScreenTitle => 'Administración de Red';

  @override
  String get ftpScreenTitle => 'Cliente FTP';

  @override
  String get filesTabTitle => 'Archivos';

  @override
  String get networkTabTitle => 'Red';

  @override
  String get ftpTabTitle => 'FTP';

  @override
  String get aiTabTitle => 'IA';

  @override
  String get settingsTabTitle => 'Configuración';

  @override
  String get currentConnectionLabel => 'Conexión Actual';

  @override
  String get wifiNetworksLabel => 'Redes WiFi';

  @override
  String get ftpHostLabel => 'Servidor';

  @override
  String get ftpPortLabel => 'Puerto';

  @override
  String get ftpUsernameLabel => 'Usuario';

  @override
  String get ftpPasswordLabel => 'Contraseña';

  @override
  String get connectButtonLabel => 'Conectar';

  @override
  String get disconnectButtonLabel => 'Desconectar';

  @override
  String get scanButtonLabel => 'Escanear Redes';

  @override
  String get uploadButtonLabel => 'Subir Archivo';

  @override
  String get downloadButtonLabel => 'Descargar';

  @override
  String get noNetworksFound => 'No se encontraron redes';

  @override
  String get remoteFiles => 'Archivos Remotos';

  @override
  String get connectionFailed => 'Conexión fallida';

  @override
  String get fileUploaded => 'Archivo subido exitosamente';

  @override
  String get fileDownloaded => 'Descargado';

  @override
  String get portScanCompleted => 'Escaneo de puertos completado';

  @override
  String get pinging => 'Haciendo ping';

  @override
  String get tracingRoute => 'Trazando ruta a';

  @override
  String get scanningPorts => 'Escaneando puertos';

  @override
  String get settings => 'Configuración';

  @override
  String get about => 'Acerca de';

  @override
  String get help => 'Ayuda';

  @override
  String get generalSettings => 'Configuración General';

  @override
  String get darkTheme => 'Tema Oscuro';

  @override
  String get darkThemeSubtitle =>
      'Habilitar modo oscuro para mejor visibilidad en luz baja';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Selecciona tu idioma preferido';

  @override
  String get autoSave => 'Guardado Automático';

  @override
  String get autoSaveSubtitle =>
      'Guardar automáticamente cambios y preferencias';

  @override
  String get networkSettings => 'Configuración de Red';

  @override
  String get networkTimeout => 'Tiempo de Espera de Red';

  @override
  String get networkTimeoutSubtitle =>
      'Tiempo de espera para operaciones de red (segundos)';

  @override
  String get batchSize => 'Tamaño de Lote';

  @override
  String get batchSizeSubtitle => 'Número de elementos a procesar en lotes';

  @override
  String get aiAssistantSettings => 'Configuración del Asistente de IA';

  @override
  String get responseStyle => 'Estilo de Respuesta';

  @override
  String get responseStyleSubtitle =>
      'Elige preferencias de respuesta del asistente de IA';

  @override
  String get concise => 'Conciso';

  @override
  String get detailed => 'Detallado';

  @override
  String get stepByStep => 'Paso a Paso';

  @override
  String get smartSuggestions => 'Sugerencias Inteligentes';

  @override
  String get smartSuggestionsSubtitle =>
      'Habilitar sugerencias de organización de archivos con IA';

  @override
  String get version => 'Versión';

  @override
  String get buildNumber => 'Número de Compilación';

  @override
  String get framework => 'Framework';

  @override
  String get database => 'Base de Datos';

  @override
  String get settingsSaved => '¡Configuración guardada exitosamente!';

  @override
  String get aiAssistant => 'Asistente de IA';

  @override
  String get askAiPlaceholder =>
      'Pregúntame sobre gestión de archivos, organización, búsqueda...';

  @override
  String get aiWelcomeMessage =>
      '¡Hola! Soy tu asistente de gestión de archivos con IA. ¿Cómo puedo ayudarte hoy?';

  @override
  String get aiOrganizeResponse =>
      '🤖 Organización de Archivos con IA:\n\n¡Puedo ayudarte a organizar tus archivos inteligentemente! Basado en investigación con LLMs como los en LlamaFS y Local-File-Organizer, aquí hay sugerencias de organización con IA:\n\n📁 Por Tipo de Contenido: Documentos, Imágenes, Videos, Música, Archivos\n📅 Por Fecha: Recientes, Este Mes, Este Año, Más Antiguos\n📊 Por Uso: Usados Frecuentemente, Rara Vez, Archivo\n🔍 Por Análisis Inteligente: Trabajo, Personal, Proyectos, Descargas\n\n¿Te gustaría que implemente alguna de estas estrategias de organización?';

  @override
  String get aiSearchResponse =>
      '🔍 Búsqueda con IA:\n\nPuedo mejorar tu búsqueda de archivos con comprensión semántica basada en LLM:\n\n📝 Lenguaje Natural: \"Encuentra mis documentos fiscales del año pasado\"\n🖼️ Búsqueda de Contenido: \"Encuentra imágenes de gatos\" (analiza contenido de imagen)\n📄 Análisis de Texto: \"Encuentra documentos sobre aprendizaje automático\"\n🔗 Coincidencia Inteligente: Entiende sinónimos y términos relacionados\n\n¡Prueba la búsqueda avanzada en la pestaña de Archivos!';

  @override
  String get aiNetworkResponse =>
      '🌐 Diagnóstico de Red:\n\nTus herramientas de red incluyen:\n\n📡 Escáner WiFi: Descubre y analiza redes inalámbricas\n🏓 Herramienta Ping: Prueba conectividad con hosts\n🗺️ Traceroute: Mapea rutas de red e identifica problemas\n🔍 Escáner de Puertos: Verifica puertos abiertos en hosts remotos\n\n¡Usa la pestaña de Red para gestión de red completa!';

  @override
  String get aiFtpResponse =>
      '☁️ Transferencia de Archivos FTP:\n\nCompartición eficiente de archivos con:\n\n🔗 Conexión al Servidor: Conecta a cualquier servidor FTP/SFTP\n📁 Navegación de Directorios: Explora sistemas de archivos remotos\n⬆️ Administrador de Subidas: Transfiere archivos con seguimiento de progreso\n⬇️ Cola de Descargas: Descarga múltiple de archivos por lotes\n\n¡Accede a herramientas FTP en la pestaña FTP!';

  @override
  String get aiHelpResponse =>
      '🧠 Capacidades del Asistente de IA:\n\n📂 Organización de Archivos: Categorización inteligente y gestión de carpetas\n🔎 Búsqueda Inteligente: Búsqueda en lenguaje natural y basada en contenido\n🌐 Herramientas de Red: Diagnóstico, monitoreo y solución de problemas\n📤 Transferencia de Archivos: Cliente FTP/SFTP con características avanzadas\n📊 Analíticas: Estadísticas de uso de archivos y recomendaciones\n🔒 Seguridad: Operaciones seguras de archivos y protección de privacidad\n\n¿Con qué tarea específica te gustaría ayuda?';

  @override
  String aiDefaultResponse(Object query) {
    return '🤔 Entiendo que preguntas sobre: \"$query\"\n\nEstoy diseñado para ayudar con gestión de archivos, organización, búsqueda, herramientas de red y operaciones FTP. Prueba preguntando sobre:\n\n• Organizar archivos por tipo o contenido\n• Buscar archivos específicos\n• Diagnóstico y herramientas de red\n• Transferencias de archivos FTP\n• Ayuda general de gestión de archivos\n\n¿En qué puedo ayudarte hoy?';
  }

  @override
  String get selectProject => 'Seleccionar Proyecto';

  @override
  String get flutterDoctor => 'Flutter Doctor';

  @override
  String get cleanCache => 'Limpiar Caché';

  @override
  String get pubCacheRepair => 'Reparar Pub Cache';

  @override
  String get exit => 'Salir';

  @override
  String get ready => 'Listo';

  @override
  String get running => 'Ejecutándose';

  @override
  String get completed => 'Completado';

  @override
  String get failed => 'Fallido';
}
