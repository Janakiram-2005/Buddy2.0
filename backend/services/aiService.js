const { VertexAI } = require('@google-cloud/vertexai');

let vertex_ai;
let generativeModel;

try {
  vertex_ai = new VertexAI({
    project: process.env.GCP_PROJECT_ID || 'convertionalai',
    location: process.env.GCP_LOCATION || 'us-central1'
  });
  generativeModel = vertex_ai.getGenerativeModel({
    model: 'gemini-1.5-flash',
  });
} catch (e) {
  console.warn('Vertex AI failed to initialize. Using mock fallback.', e.message);
}

exports.generateSchedule = async (prompt) => {
  try {
    if (!generativeModel) throw new Error('Vertex AI model not initialized');
    const fullPrompt = `Generate a study schedule in JSON format for the following request: ${prompt}.
    The JSON should be an array of objects, each containing:
    subject, topic, date (YYYY-MM-DD), startTime (HH:mm), endTime (HH:mm), description.
    Return ONLY the JSON.`;

    const resp = await generativeModel.generateContent(fullPrompt);
    const content = resp.response.candidates[0].content.parts[0].text;
    const cleanJson = content.replace(/```json|```/g, '').trim();
    return JSON.parse(cleanJson);
  } catch (error) {
    console.warn('Vertex AI generation failed, falling back to mock schedule generator:', error.message);
    // Parse possible subject/topic/student from prompt
    const matches = prompt.match(/for\s+([A-Za-z0-9\s]+)/i);
    const topic = matches ? matches[1].trim() : 'Core Topic Review';
    const subject = prompt.toLowerCase().includes('physics') ? 'Physics' : (prompt.toLowerCase().includes('chemistry') ? 'Chemistry' : 'Mathematics');
    
    const today = new Date().toISOString().split('T')[0];
    const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
    
    return [
      {
        subject: subject,
        topic: `${topic} - Part 1`,
        date: today,
        startTime: '09:00',
        endTime: '11:00',
        description: 'Read introduction, study formulas, and work through example problems.',
        expectedDuration: 120
      },
      {
        subject: subject,
        topic: `${topic} - Part 2`,
        date: tomorrow,
        startTime: '14:00',
        endTime: '16:00',
        description: 'Deep dive into practice exercises, complete practice quiz, and note down questions.',
        expectedDuration: 120
      }
    ];
  }
};

exports.generateQuiz = async (subject, topic, count = 5) => {
  try {
    if (!generativeModel) throw new Error('Vertex AI model not initialized');
    const prompt = `Generate a quiz with ${count} questions for subject: ${subject} and topic: ${topic}.
    The format should be a JSON object with:
    title, subject, topic, questions (array of objects with: type (MCQ/TrueFalse/ShortAnswer), question, options (array for MCQ), correctAnswer, explanation).
    Return ONLY the JSON.`;

    const resp = await generativeModel.generateContent(prompt);
    const content = resp.response.candidates[0].content.parts[0].text;
    const cleanJson = content.replace(/```json|```/g, '').trim();
    return JSON.parse(cleanJson);
  } catch (error) {
    console.warn('Vertex AI generation failed, falling back to mock quiz generator:', error.message);
    return {
      title: `${topic} Quick Diagnostic Quiz`,
      subject: subject,
      topic: topic,
      questions: [
        {
          type: 'MCQ',
          question: `Which of the following is a primary characteristic of ${topic}?`,
          options: ['Option A: Fundamental property', 'Option B: Secondary effect', 'Option C: Negligible factor', 'Option D: None of the above'],
          correctAnswer: 'Option A: Fundamental property',
          explanation: `In standard theory, ${topic} is defined primarily by Option A due to its basic behavior.`
        },
        {
          type: 'TrueFalse',
          question: `True or False: ${topic} is a constant value under all standard conditions.`,
          options: ['True', 'False'],
          correctAnswer: 'False',
          explanation: `${topic} varies based on external environmental factors like temperature or force.`
        },
        {
          type: 'ShortAnswer',
          question: `Briefly define the primary goal of studying ${topic}.`,
          correctAnswer: 'To understand its direct physical and practical application.',
          explanation: `Studying ${topic} allows students to resolve engineering and practical math equations.`
        }
      ]
    };
  }
};

exports.recommendResources = async (topic) => {
  try {
    if (!generativeModel) throw new Error('Vertex AI model not initialized');
    const prompt = `Recommend 3-5 high-quality educational resources (YouTube links, PDF links, or website URLs) for the topic: ${topic}.
    Return as a JSON array of strings.
    Return ONLY the JSON.`;

    const resp = await generativeModel.generateContent(prompt);
    const content = resp.response.candidates[0].content.parts[0].text;
    const cleanJson = content.replace(/```json|```/g, '').trim();
    return JSON.parse(cleanJson);
  } catch (error) {
    console.warn('Vertex AI generation failed, falling back to mock resource generator:', error.message);
    const slug = topic.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    return [
      `https://www.youtube.com/results?search_query=${encodeURIComponent(topic + ' crash course')}`,
      `https://example.com/notes/${slug}-detailed-notes.pdf`,
      `https://en.wikipedia.org/wiki/${encodeURIComponent(topic)}`
    ];
  }
};

exports.analyticsSummary = async (metrics) => {
  try {
    if (!generativeModel) throw new Error('Vertex AI model not initialized');
    const prompt = `Analyze the following student performance metrics and generate 3-5 actionable study recommendations in a JSON array of strings.
    Metrics: ${JSON.stringify(metrics)}
    Return ONLY the JSON.`;

    const resp = await generativeModel.generateContent(prompt);
    const content = resp.response.candidates[0].content.parts[0].text;
    const cleanJson = content.replace(/```json|```/g, '').trim();
    return JSON.parse(cleanJson);
  } catch (error) {
    console.warn('Vertex AI generation failed, falling back to mock analytics summary generator:', error.message);
    return [
      "Review the concepts in subjects where quiz accuracy is below 70%.",
      "Dedicate at least 30 more minutes daily to focus sessions to improve study plan completion.",
      "Submit pending tasks on time to ensure continuous assessment feedback.",
      "Review 'Not Understood' topics before attempting upcoming quizzes."
    ];
  }
};
