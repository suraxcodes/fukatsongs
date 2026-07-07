/// Application-wide sentinel values and shared model instances.
///
/// These replace the legacy [mediaItemModelNull] sentinel that depended
/// on [MediaItemModel]. All player code should use [trackNull] instead.
// This file replaces the old, complicated null-handling system.
// Now you just use `trackNull` everywhere instead of `MediaItemModel()` or `Track(id: 'Null', ...)`.
library sentinel_values;

import 'package:fukatsongs/core/models/exported.dart';

/// A null/empty [Track] sentinel used as a default value
/// where a non-nullable Track is required but no track is loaded.
const Track trackNull = Track(
  id: 'Null',
  title: 'Null',
  artists: [],
  thumbnail: Artwork(url: '', layout: ImageLayout.square),
  isExplicit: false,
);

/// Check whether a [Track] is the null sentinel.
bool isTrackNull(Track track) => track.id == 'Null' && track.title == 'Null';
