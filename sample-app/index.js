const express = require('express');
const app = express();
const PORT = 8080; // Fargate는 8080을 선호합니다.

app.get('/', (req, res) => {
  res.send('<h1>v1.0.0 - Hello Blue World!</h1>'); 
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});