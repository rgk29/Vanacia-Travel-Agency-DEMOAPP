const express = require('express');
const axios = require('axios');
const app = express();
require('dotenv').config();

// Middleware CORS
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
   next();
});

// Configuration RapidAPI
const RAPIDAPI_CONFIG = {
  baseURL: 'https://sky-scrapper.p.rapidapi.com',
  headers: {
    'x-rapidapi-key': process.env.RAPIDAPI_KEY,
    'x-rapidapi-host': 'sky-scrapper.p.rapidapi.com',
    'Accept': 'application/json' // Header critique pour certaines APIs
  }
};

async function rapidApiRequest(endpoint) {
  try {
    const response = await axios({
      method: 'GET',
      url: `${RAPIDAPI_CONFIG.baseURL}${endpoint}`,
      headers: RAPIDAPI_CONFIG.headers,
      timeout: 5000
    });
    return JSON.stringify(response.data);
  } catch (error) {
    throw new Error(`API request failed: ${error.message}`);
  }
}

// Endpoints
app.get('/api/locales', async (req, res) => {
  try {
    const response = await axios.get('https://sky-scrapper.p.rapidapi.com/api/v1/getLocale', {
      headers: {
        'X-RapidAPI-Key': process.env.RAPIDAPI_KEY,
        'X-RapidAPI-Host': 'sky-scrapper.p.rapidapi.com'
      }
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/server-status', async (req, res) => {
  try {
    const response = await axios.get('https://sky-scrapper.p.rapidapi.com/api/v1/checkServer', {
      headers: {
        'X-RapidAPI-Key': process.env.RAPIDAPI_KEY,
        'X-RapidAPI-Host': 'sky-scrapper.p.rapidapi.com'
      }
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/config', async (req, res) => {
  try {
    const response = await axios.get('https://sky-scrapper.p.rapidapi.com/api/v1/getConfig', {
      headers: {
        'X-RapidAPI-Key': process.env.RAPIDAPI_KEY,
        'X-RapidAPI-Host': 'sky-scrapper.p.rapidapi.com'
      }
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Démarrer le serveur
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server ready on port ${PORT}`);
});