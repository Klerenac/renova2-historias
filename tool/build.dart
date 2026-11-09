// Valida las historias y genera el sitio que descarga la app.
//
//   dart tool/build.dart            -> solo valida
//   dart tool/build.dart _site      -> valida y genera _site/ (index.json + historias)
//
// Si algo está mal, termina con error y NO se publica nada: la app nunca
// recibe un archivo roto.
import 'dart:convert';
import 'dart:io';

final idRe = RegExp(r'^\d{4}_T[1-4]_W\d{2}$');
final ytRe = RegExp(r'^[A-Za-z0-9_-]{11}$');
final fechaRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

const campos = {
  'id', 'fecha',
  'tituloEs', 'tituloEn', 'tituloPt',
  'resumenEs', 'resumenEn', 'resumenPt',
  'youtubeIdEs', 'youtubeIdEn', 'youtubeIdPt',
  'textoEs', 'textoEn', 'textoPt',
};

void main(List<String> args) {
  final errores = <String>[];
  final avisos = <String>[];
  final entradas = <Map<String, dynamic>>[];
  final ids = <String>{};

  final archivos = Directory('historias')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final f in archivos) {
    final nombre = f.uri.pathSegments.last;
    final bytes = f.readAsBytesSync();
    Map<String, dynamic> h;
    try {
      h = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (e) {
      errores.add('$nombre: JSON inválido (¿falta una coma o comillas?) -> $e');
      continue;
    }

    String txt(String k) => (h[k] as String? ?? '').trim();
    final id = txt('id');

    if (!idRe.hasMatch(id)) {
      errores.add('$nombre: "id" debe ser AAAA_T#_W## (ej. 2026_T4_W01), no "$id".');
    }
    if (nombre != '$id.json') {
      errores.add('$nombre: el archivo debe llamarse "$id.json".');
    }
    if (!ids.add(id)) errores.add('$nombre: id repetido "$id".');

    for (final k in h.keys) {
      if (!campos.contains(k)) avisos.add('$nombre: campo desconocido "$k" (se ignora).');
    }
    for (final k in h.keys) {
      if (h[k] is! String) errores.add('$nombre: "$k" debe ser texto entre comillas.');
    }

    if (txt('tituloEs').isEmpty) errores.add('$nombre: falta "tituloEs".');
    if (txt('textoEs').isEmpty) errores.add('$nombre: falta "textoEs".');
    for (final l in ['En', 'Pt']) {
      if (txt('titulo$l').isEmpty || txt('texto$l').isEmpty) {
        avisos.add('$nombre: falta título o texto en ${l.toUpperCase()}.');
      }
    }

    for (final l in ['Es', 'En', 'Pt']) {
      final yt = txt('youtubeId$l');
      if (yt.isNotEmpty && !ytRe.hasMatch(yt)) {
        errores.add('$nombre: "youtubeId$l" debe ser solo el ID de 11 caracteres '
            '(lo que va después de youtu.be/), no "$yt".');
      }
    }

    final fecha = txt('fecha');
    if (fecha.isNotEmpty &&
        (!fechaRe.hasMatch(fecha) || DateTime.tryParse(fecha) == null)) {
      errores.add('$nombre: "fecha" debe ser AAAA-MM-DD, no "$fecha".');
    }

    entradas.add({
      'id': id,
      if (fecha.isNotEmpty) 'fecha': fecha,
      'rev': _rev(bytes),
      'archivo': 'historias/$nombre',
    });
  }

  for (final a in avisos) {
    stdout.writeln('AVISO  $a');
  }
  if (errores.isNotEmpty) {
    for (final e in errores) {
      stderr.writeln('ERROR  $e');
    }
    stderr.writeln('\n${errores.length} error(es). No se publica nada.');
    exit(1);
  }
  stdout.writeln('OK: ${entradas.length} historias válidas.');

  if (args.isEmpty) return;

  final out = Directory(args.first);
  if (out.existsSync()) out.deleteSync(recursive: true);
  Directory('${out.path}/historias').createSync(recursive: true);
  for (final f in archivos) {
    f.copySync('${out.path}/historias/${f.uri.pathSegments.last}');
  }
  entradas.sort((a, b) => (b['id'] as String).compareTo(a['id'] as String));
  final index = {
    'schema': 1,
    'generado': DateTime.now().toUtc().toIso8601String(),
    'historias': entradas,
  };
  File('${out.path}/index.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(index));
  File('${out.path}/.nojekyll').writeAsStringSync('');
  stdout.writeln('Sitio generado en ${out.path}/');
}

/// Huella del contenido (FNV-1a 32 bits + tamaño): cambia si el archivo cambia.
String _rev(List<int> bytes) {
  var h = 0x811c9dc5;
  for (final b in bytes) {
    h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
  }
  return '${h.toRadixString(16).padLeft(8, '0')}-${bytes.length}';
}
