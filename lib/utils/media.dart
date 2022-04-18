enum MediaType {
  photo,
  video
}

class Media {
  late final String id;
  final MediaType type;
  late final String thumbnailURL;
  late final String highresURL;
  late final String localPath;
  late bool uploadedSuccessfully;
  late final DateTime uploadedTimestamp;

  Media(this.id, this.type, this.thumbnailURL, this.highresURL);

  Media.uploaded(this.id, this.type, this.thumbnailURL, this.highresURL,
      this.localPath, this.uploadedTimestamp) {
    uploadedSuccessfully = true;
  }

  Media.pendingUpload(this.type, this.localPath) {
    uploadedSuccessfully = false;
  }

  Media.fromJson(Map<String, dynamic> json) :
        id = json['id'],
        type = MediaType.values.byName(json['type']),
        thumbnailURL = json['thumbnailURL'],
        highresURL = json['highresURL'],
        localPath = json['localPath'],
        uploadedSuccessfully = json['uploadedSuccessfully'] == "true" ? true : false,
        uploadedTimestamp = DateTime.parse(json['uploadedTimestamp']);

  Map<String, dynamic> toJson() => {
    'id' : id,
    'type': type.name,
    'thumbnailURL' : thumbnailURL,
    'highresURL' : highresURL,
    'localPath' : localPath,
    'uploadedSuccessfully' : uploadedSuccessfully ? "true" : "false",
    'uploadedTimestamp' : uploadedTimestamp.toIso8601String(),
  };

}

class Collection {
  final String name;
  final String information;
  final String id;
  final bool shared;
  final List<Media> images; // may also be previewImages and the rest gathered
  // in collection_viewer, which is probably better. new field needed though

  Collection(this.name, this.information, this.id, this.shared, this.images);
}


class MediaCollectionsLists {
  final List<Collection> collections;
  final List<Media> media;

  MediaCollectionsLists(this.collections, this.media);
}

class MediaFolder {
  String path;
  int itemCount;

  MediaFolder(this.path, this.itemCount);

  MediaFolder.fromJson(Map<String, dynamic> json)
      : path = json['path'],
        itemCount = json['itemCount'];

  Map<String, dynamic> toJson() => {
    'path' : path,
    'itemCount' : itemCount
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
