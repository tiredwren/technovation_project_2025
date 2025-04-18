const functions = require('firebase-functions');
const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require("@google/generative-ai");

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

const genAI = new GoogleGenerativeAI("AIzaSyATi56IvBnjGbZ5qhFOLtAPl7mf5owwrdI");

app.post('/generate-image', async (req, res) => {
  const prompt = req.body.prompt || "delicious dish on a plate";

  try {
    const model = genAI.getGenerativeModel({ model: "models/gemini-pro" });

    const result = await model.generateContent(`Generate a high-quality, realistic food image of ${prompt}. Output only an image.`);

    const response = result.response;
    const imageUrl = response.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;

    if (imageUrl) {
      res.json({ image_url: `data:image/png;base64,${imageUrl}` });
    } else {
      throw new Error('No image found');
    }
  } catch (e) {
    console.error(e);
    res.status(500).send("Image generation failed");
  }
});

exports.generateImage = functions.https.onRequest(app);
