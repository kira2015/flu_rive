class AudioModel {
  List<AudioData>? data;
  int? errNo;
  dynamic failed;
  int? ok;

  AudioModel({this.data, this.errNo, this.failed, this.ok});

  AudioModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <AudioData>[];
      json['data'].forEach((v) {
        data!.add(AudioData.fromJson(v));
      });
    }
    errNo = json['err_no'];
    failed = json['failed'];
    ok = json['ok'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['err_no'] = errNo;
    data['failed'] = failed;
    data['ok'] = ok;
    return data;
  }
  AudioModel.copy(AudioModel from)
      : this(
          data: from.data,
          errNo: from.errNo,
          failed: from.failed,
          ok: from.ok,
        );
}

class AudioData {
  int? bg;
  int? ed;
  String? onebest;
  String? speaker;

  AudioData({this.bg, this.ed, this.onebest, this.speaker});

  AudioData.fromJson(Map<String, dynamic> json) {
    bg = int.tryParse(json['bg']);
    ed = int.tryParse(json['ed']);
    onebest = json['onebest'];
    speaker = json['speaker'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['bg'] = bg;
    data['ed'] = ed;
    data['onebest'] = onebest;
    data['speaker'] = speaker;
    return data;
  }
  AudioData.copy(AudioData from)
      : this(
          bg: from.bg,
          ed: from.ed,
          onebest: from.onebest,
          speaker: from.speaker,
        );
}
