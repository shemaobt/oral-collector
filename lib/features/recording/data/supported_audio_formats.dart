const kSupportedAudioExtensions = <String>{'mp3', 'wav', 'm4a', 'ogg'};

const kSupportedAudioMimeTypes = <String, String>{
  'mp3': 'audio/mpeg',
  'wav': 'audio/wav',
  'm4a': 'audio/mp4',
  'ogg': 'audio/ogg',
};

const kMaxImportFileBytes = 500 * 1024 * 1024;

String kSupportedAudioExtensionsDisplay() =>
    kSupportedAudioExtensions.map((e) => e.toUpperCase()).join(', ');
