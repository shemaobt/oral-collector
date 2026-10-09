/// A metade da recuperação que só o aparelho tem: o diretório de documentos e
/// os arquivos de segmento dentro dele.
///
/// A recuperação é, na maior parte, decisão sobre estado — quais sessões
/// ficaram em aberto, quais terminaram sem que ninguém salvasse, o que a lista
/// de não salvas deve oferecer. Isso são consultas ao banco e vale igual nas
/// duas plataformas. O que **varre disco** não vale: no navegador não há
/// diretório para listar nem segmentos para reparar, porque a captura é um
/// blob só (ENG-519, fatia 2).
///
/// A separação é por exportação condicional, como
/// [/lib/core/platform/file_ops.dart] e a conexão do banco já fazem, e não por
/// `kIsWeb` espalhado: é isto que tira o `dart:io` do caminho compilado para o
/// navegador, e o `flutter build web` é quem prova.
library;

export 'recovery_disk_native.dart'
    if (dart.library.js_interop) 'recovery_disk_web.dart';
