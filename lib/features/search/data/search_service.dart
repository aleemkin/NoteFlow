import 'dart:convert';

import 'package:noteflow/core/platform/platform.dart';
import 'package:noteflow/features/vault/vault.dart';

/// Fast vault-wide full-text content search service.
class SearchService {
  final VaultManager vaultManager;
  final VaultTreeRepository treeRepository;

  /// Creates a [SearchService] with [vaultManager] and [treeRepository].
  SearchService({required this.vaultManager, required this.treeRepository});

  /// Searches all markdown files in the vault for occurrences of [query].
  ///
  /// Returns matching file paths with highlighted preview snippets,
  /// ordered by relevance and match count descending.
  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final fs = vaultManager.fileSystem;
    if (fs == null) return [];

    final results = <SearchResult>[];
    final files = treeRepository.allSupportedFiles;
    final lowerQuery = query.toLowerCase();

    for (final file in files) {
      if (!file.uri.path.endsWith('.md')) continue;
      try {
        final bytes = await fs.readBytes(file.uri);
        final text = utf8.decode(bytes, allowMalformed: true);
        final lowerText = text.toLowerCase();
        final idx = lowerText.indexOf(lowerQuery);
        if (idx >= 0) {
          // Extract snippet
          final start = (idx - 40).clamp(0, text.length);
          final end = (idx + query.length + 60).clamp(0, text.length);
          final snippet = text.substring(start, end).replaceAll('\n', ' ');

          // Count matches
          var count = 0;
          var searchFrom = 0;
          while (true) {
            final found = lowerText.indexOf(lowerQuery, searchFrom);
            if (found == -1) break;
            count++;
            searchFrom = found + 1;
          }

          results.add(
            SearchResult(
              uri: file.uri,
              fileName: file.name,
              snippet: snippet,
              matchCount: count,
            ),
          );
        }
      } catch (_) {
        // Skip unreadable files
      }
    }

    // Sort by match count descending
    results.sort((a, b) => b.matchCount.compareTo(a.matchCount));
    return results;
  }
}

/// Represents a matching document result in a vault-wide search.
final class SearchResult {
  /// The URI of the matching file.
  final VaultUri uri;

  /// The file name.
  final String fileName;

  /// A contextual snippet of text surrounding the match.
  final String snippet;

  /// The total number of match occurrences within the file.
  final int matchCount;

  /// Creates a [SearchResult] instance.
  const SearchResult({
    required this.uri,
    required this.fileName,
    required this.snippet,
    required this.matchCount,
  });
}
