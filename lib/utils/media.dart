class Media {

  Media();

  Media.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() => {};

}


class Photo extends Media {
  final String photoID;
  final String thumbnailURL;
  final String highresURL;

  Photo(this.photoID, this.thumbnailURL, this.highresURL);

  @override
  Photo.fromJson(Map<String, dynamic> json)
      : photoID = json['photoID'],
        thumbnailURL = json['thumbnailURL'],
        highresURL = json['highresURL'];

  @override
  Map<String, dynamic> toJson() => {
    'originalType': "photo",
    'photoID' : photoID,
    'thumbnailURL' : thumbnailURL,
    'highresURL' : highresURL,
  };
}

// TODO: Convert/fully implement this class
class Video extends Media {
  final String photoID;
  final String thumbnailURL;
  final String highresURL;

  Video(this.photoID, this.thumbnailURL, this.highresURL);

  @override
  Video.fromJson(Map<String, dynamic> json)
      : photoID = json['photoID'],
        thumbnailURL = json['thumbnailURL'],
        highresURL = json['highresURL'];

  @override
  Map<String, dynamic> toJson() => {
    'originalType': "video",
    'photoID' : photoID,
    'thumbnailURL' : thumbnailURL,
    'highresURL' : highresURL,
  };
}


class Collection {
  final String name;
  final String information;
  final String url;
  final bool shared;
  final List<Photo> images; // may also be previewImages and the rest gathered
  // in collection_viewer, which is probably better. new field needed though

  Collection(this.name, this.information, this.url, this.shared, this.images);
}


class PhotosCollectionsLists {
  final List<Collection> collections;
  final List<Photo> photos;

  PhotosCollectionsLists(this.collections, this.photos);
}

class MediaFolder {
  String path;

  MediaFolder(this.path);

  MediaFolder.fromJson(Map<String, dynamic> json)
      : path = json['path'];

  Map<String, dynamic> toJson() => {
    'path' : path,
  };
}

class MediaFolderList {
  List<MediaFolder>? mediaFolders;

  MediaFolderList(this.mediaFolders);

  MediaFolderList.fromJson(Map<String, dynamic> json)
      : mediaFolders = json['mediaFolders'] != null ? List<MediaFolder>.from(json['mediaFolders']) : null;

  Map<String, dynamic> toJson() => {
    'mediaFolders' : mediaFolders,
  };
}
