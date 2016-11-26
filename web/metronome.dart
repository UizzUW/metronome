import "dart:html";
import "dart:web_audio";
import "./metronomeworker.dart";

class Note {
  int note;
  double time;
}

// tempo (in bpm)
const _TEMPO = 120;
// How frequently to call scheduling function (in ms)
const _LOOKAHEAD = 25;
// How far ahead to schedule audio (sec)
// This is calculated from lookahead, and overlaps
// with next interval (in case the timer is late)
const _SCHEDULE_AHEAD_TIME = 0.1;
// 0 == 16th, 1 == 8th, 2 == quarter note
const _NOTE_RESOLUTION = 2;
// length of "beep" (in s)
var _NOTE_LENGTH = 0.05;

AudioContext audioContext = null;
bool isPlaying = false;
// What note is currently last scheduled?
int current16th = 0;
// when the next note is due.
double nextNoteTime = 0.0;
// The worker used to fire timer messages
MetronomeWorker timerWorker;

scheduleNote(Note note) {
  if ((_NOTE_RESOLUTION == 1) && (note.note % 2 != 0))
    return; // we're not playing non-8th 16th notes
  if ((_NOTE_RESOLUTION == 2) && (note.note % 4 != 0))
    return; // we're not playing non-quarter 8th notes

  // create an oscillator
  var osc = audioContext.createOscillator();
  osc.connectNode(audioContext.destination);
  if (note.note % 16 == 0) // beat 0 == high pitch
    osc.frequency.value = 880.0;
  else if (note.note % 4 == 0) // quarter notes = medium pitch
    osc.frequency.value = 440.0;
  else // other 16th notes = low pitch
    osc.frequency.value = 220.0;

  osc.start(note.time);
  osc.stop(note.time + _NOTE_LENGTH);
}

scheduler() {
  // while there are notes that will need to play before the next interval,
  // schedule them and advance the pointer.
  while (nextNoteTime < audioContext.currentTime + _SCHEDULE_AHEAD_TIME) {
    var newNote = new Note()
      ..note = current16th
      ..time = nextNoteTime;
    scheduleNote(newNote);
    // Notice this picks up the CURRENT tempo value to calculate beat length.
    var secondsPer16th = 60.0 / _TEMPO / 4;
    nextNoteTime += secondsPer16th;
    current16th++;
    if (current16th == 16) {
      current16th = 0;
    }
  }
}

play() {
  isPlaying = !isPlaying;

  if (isPlaying) {
    // start playing
    current16th = 0;
    nextNoteTime = audioContext.currentTime;
    timerWorker.start();
    return "stop";
  } else {
    timerWorker.stop();
    return "play";
  }
}

init() {
  audioContext = new AudioContext();
  timerWorker = new MetronomeWorker();

  timerWorker.onTick.listen((_) => scheduler());
  timerWorker.changeInterval(_LOOKAHEAD);
}

main() {
  var playButton = querySelector("#playButton");
  playButton.onClick.listen((e) {
    playButton.innerHtml = play();
  });

  init();
}
