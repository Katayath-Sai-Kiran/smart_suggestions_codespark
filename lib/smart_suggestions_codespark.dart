/// On-device "related items" for Flutter — suggest similar content by meaning,
/// fully offline, no API keys. Powered by local embeddings from
/// ai_core_codespark + a local MiniLM model.
library;

export 'src/exceptions.dart';
export 'src/smart_suggestions.dart';
export 'src/suggestion_index.dart';
export 'src/suggestion_result.dart';
export 'src/suggestion_embedder.dart';
export 'src/suggestions_list.dart';

export 'package:ai_core_codespark/ai_core_codespark.dart'
    show
        ModelConfig,
        ModelCatalog,
        ProgressCallback,
        CodesparkException,
        EngineNotInitializedException,
        ModelDownloadOfflineException,
        InsufficientStorageException,
        Similarity,
        ScoredIndex,
        Pooling,
        PoolingStrategy;
