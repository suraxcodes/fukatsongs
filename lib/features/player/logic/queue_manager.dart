import 'package:audio_service/audio_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/song.dart';
import '../../../core/audio/audio_handler.dart';

class QueueManager {
  final MusicAudioHandler _handler;
  final Box _queueBox = Hive.box('queue_state');

  List<Song> _originalQueue = [];
  List<Song> _shuffledQueue = [];
  bool _isShuffleModeEnabled = false;

  QueueManager(this._handler);

  List<Song> get currentQueue => _isShuffleModeEnabled ? _shuffledQueue : _originalQueue;

  void setQueue(List<Song> songs, {int initialIndex = 0}) {
    _originalQueue = List.from(songs);
    if (_isShuffleModeEnabled) {
      _shuffledQueue = List.from(songs)..shuffle();
    }
    
    _updateHandlerQueue();
    _saveQueue();
  }

  void addToQueue(Song song) {
    _originalQueue.add(song);
    if (_isShuffleModeEnabled) {
      _shuffledQueue.add(song);
    }
    _updateHandlerQueue();
    _saveQueue();
  }

  void toggleShuffle() {
    _isShuffleModeEnabled = !_isShuffleModeEnabled;
    if (_isShuffleModeEnabled) {
      _shuffledQueue = List.from(_originalQueue)..shuffle();
    }
    _updateHandlerQueue();
  }

  void _updateHandlerQueue() {
    final mediaItems = currentQueue.map((song) => MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.albumName,
      duration: Duration(seconds: song.duration),
      artUri: Uri.parse(song.imageUrl),
    )).toList();
    
    _handler.updateQueue(mediaItems);
  }

  void _saveQueue() {
    _queueBox.put('current_queue', _originalQueue.map((s) => s.id).toList());
  }

  // Restore logic would go here, mapping IDs back to Songs from a cache
}
