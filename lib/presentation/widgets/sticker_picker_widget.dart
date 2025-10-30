import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nookly/data/services/giphy_service.dart';
import 'package:nookly/core/utils/logger.dart';

class StickerPickerWidget extends StatefulWidget {
  final Function(GiphySticker) onStickerSelected;
  final VoidCallback? onClose;

  const StickerPickerWidget({
    Key? key,
    required this.onStickerSelected,
    this.onClose,
  }) : super(key: key);

  @override
  State<StickerPickerWidget> createState() => _StickerPickerWidgetState();
}

class _StickerPickerWidgetState extends State<StickerPickerWidget> {
  final GiphyService _giphyService = GiphyService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<GiphySticker> _stickers = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _currentQuery = '';
  int _currentOffset = 0;
  static const int _pageSize = 25;
  bool _hasMoreData = true;
  
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadTrendingStickers();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _currentQuery) {
        _performSearch(_searchController.text);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreStickers();
    }
  }

  Future<void> _loadTrendingStickers() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _currentQuery = '';
      _currentOffset = 0;
      _hasMoreData = true;
    });

    try {
      final response = await _giphyService.getTrendingStickers(
        offset: _currentOffset,
        limit: _pageSize,
      );
      
      final stickers = _parseStickersFromResponse(response);
      
      setState(() {
        _stickers = stickers;
        _isLoading = false;
        _currentOffset += _pageSize;
      });
    } catch (e) {
      AppLogger.error('❌ Error loading trending stickers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      _loadTrendingStickers();
      return;
    }

    if (_isSearching) return;
    
    setState(() {
      _isSearching = true;
      _currentQuery = query;
      _currentOffset = 0;
      _hasMoreData = true;
    });

    try {
      final response = await _giphyService.searchStickers(
        query: query,
        offset: _currentOffset,
        limit: _pageSize,
      );
      
      final stickers = _parseStickersFromResponse(response);
      
      setState(() {
        _stickers = stickers;
        _isSearching = false;
        _currentOffset += _pageSize;
      });
    } catch (e) {
      AppLogger.error('❌ Error searching stickers: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _loadMoreStickers() async {
    if (_isLoading || _isSearching || !_hasMoreData) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = _currentQuery.isEmpty
          ? await _giphyService.getTrendingStickers(
              offset: _currentOffset,
              limit: _pageSize,
            )
          : await _giphyService.searchStickers(
              query: _currentQuery,
              offset: _currentOffset,
              limit: _pageSize,
            );
      
      final stickers = _parseStickersFromResponse(response);
      
      setState(() {
        _stickers.addAll(stickers);
        _isLoading = false;
        _currentOffset += _pageSize;
        _hasMoreData = stickers.length == _pageSize;
      });
    } catch (e) {
      AppLogger.error('❌ Error loading more stickers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<GiphySticker> _parseStickersFromResponse(Map<String, dynamic> response) {
    try {
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((stickerData) => GiphySticker.fromJson(stickerData as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.error('❌ Error parsing stickers from response: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_emotions,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Choose a Sticker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search stickers...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.6),
                ),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Stickers grid
          Expanded(
            child: _buildStickersGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildStickersGrid() {
    if (_isLoading && _stickers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_stickers.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.white.withOpacity(0.6),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _currentQuery.isEmpty ? 'No trending stickers found' : 'No stickers found for "${_currentQuery}"',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _stickers.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _stickers.length) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        final sticker = _stickers[index];
        return _buildStickerItem(sticker);
      },
    );
  }

  Widget _buildStickerItem(GiphySticker sticker) {
    return GestureDetector(
      onTap: () {
        widget.onStickerSelected(sticker);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Sticker image
              Positioned.fill(
                child: Image.network(
                  sticker.previewUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFF2A2A2A),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF2A2A2A),
                      child: Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.white.withOpacity(0.6),
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Overlay with title
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Text(
                    sticker.title.isNotEmpty ? sticker.title : 'Sticker',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Nunito',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}




