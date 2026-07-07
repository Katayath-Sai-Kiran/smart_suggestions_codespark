String readFile(String path) =>
    throw UnsupportedError('File I/O is not available on web. '
        'Provide your own persistence layer or use a non-web platform.');

void writeFile(String path, String content) =>
    throw UnsupportedError('File I/O is not available on web. '
        'Provide your own persistence layer or use a non-web platform.');
