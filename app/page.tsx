import AudioRecorder from "./components/AudioRecorder";

export default function Home() {
  return (
    <main className="flex flex-col items-center p-5 text-center">
      <h1 className="text-3xl font-bold mb-4">Audio Recorder App</h1>
      <AudioRecorder />
    </main>
  );
}
