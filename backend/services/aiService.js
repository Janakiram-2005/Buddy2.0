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

exports.generateQuiz = async (subject, topic, count = 5, difficulty = 'medium', diagrams = 'without diagrams', style = 'statement type', format = 'mixed') => {
  try {
    if (!generativeModel) throw new Error('Vertex AI model not initialized');
    const prompt = `Generate a quiz with ${count} questions for subject: ${subject} and topic: ${topic}.
    Please apply the following filters/constraints:
    - Difficulty level: ${difficulty}
    - Diagrams: ${diagrams} ${diagrams === 'with diagrams' ? '(please describe the diagram/graph textually in the question text or a separate diagramDescription field, and explain it in the explanation)' : ''}
    - Question Style: ${style}
    - Question Format: ${format}
    
    The format should be a JSON object with:
    title, subject, topic, questions (array of objects with: type (MCQ/TrueFalse/ShortAnswer/FillInTheBlank), question, options (array for MCQ, empty or omitted for others), correctAnswer, explanation, diagramDescription (optional string describing diagram if applicable)).
    Return ONLY the JSON.`;

    const resp = await generativeModel.generateContent(prompt);
    const content = resp.response.candidates[0].content.parts[0].text;
    const cleanJson = content.replace(/```json|```/g, '').trim();
    return JSON.parse(cleanJson);
  } catch (error) {
    console.warn('Vertex AI generation failed, falling back to mock quiz generator:', error.message);
    const mockQuestions = [];
    const actualFormat = format || 'mixed';
    
    for (let i = 1; i <= count; i++) {
      let qType = 'MCQ';
      if (actualFormat === 'fill in the blank') {
        qType = 'FillInTheBlank';
      } else if (actualFormat === 'mixed') {
        qType = i % 2 === 0 ? 'MCQ' : 'FillInTheBlank';
      }
      
      const isNumerical = style === 'mixed numerical' && i % 2 === 0;
      const questionText = isNumerical 
        ? `What is the value of the formula parameter in ${topic} if the inputs are 5 and 10? (${difficulty} level, ${diagrams})`
        : `Which statement best describes ${topic}? (${difficulty} level, ${diagrams})`;
      
      mockQuestions.push({
        type: qType,
        question: questionText,
        options: qType === 'MCQ' ? ['Option A (Correct)', 'Option B', 'Option C', 'Option D'] : [],
        correctAnswer: qType === 'MCQ' ? 'Option A (Correct)' : '50',
        explanation: `This is a mock explanation explaining ${topic} for a ${difficulty} level question under ${style} style.`,
        ...(diagrams === 'with diagrams' && { diagramDescription: 'A diagram showing the flow of the process.' })
      });
    }

    return {
      title: `${topic} Quick Diagnostic Quiz (${difficulty})`,
      subject: subject,
      topic: topic,
      questions: mockQuestions
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

exports.chatWithAI = async (message, imageBase64, history = []) => {
  try {
    if (!generativeModel) throw new Error('Vertex AI model not initialized');
    
    const parts = [];
    if (imageBase64) {
      const base64Data = imageBase64.split(',')[1] || imageBase64;
      const mimeType = imageBase64.split(';')[0].split(':')[1] || 'image/jpeg';
      parts.push({
        inlineData: {
          data: base64Data,
          mimeType: mimeType
        }
      });
    }
    parts.push({ text: message });

    let promptParts = [];
    if (history && Array.isArray(history) && history.length > 0) {
      promptParts.push({ text: "Conversation history so far for context:\n" + history.map(h => `${h.role}: ${h.text}`).join('\n') + "\n\n" });
    }
    promptParts = [...promptParts, ...parts];


    const resp = await generativeModel.generateContent({ contents: [{ role: 'user', parts: promptParts }] });
    const replyText = resp.response.candidates[0].content.parts[0].text;
    return { reply: replyText };
  } catch (error) {
    console.warn('Vertex AI chat failed, falling back to mock reply:', error.message);
    return {
      reply: `I received your message: "${message}". (Mock response - Gemini AI service currently offline.)`
    };
  }
};

exports.suggestTopics = async (subject, description = '') => {
  try {
    if (!generativeModel) throw new Error('Vertex AI model not initialized');
    const prompt = `Suggest 5 relevant study topics/sub-topics for the subject "${subject}"${description ? ` based on the description: "${description}"` : ''}.
    For each topic, provide a short 1-2 sentence description explaining what it covers.
    Return the response as a JSON array of objects, where each object has "topic" and "description" fields.
    Return ONLY the JSON.`;

    const resp = await generativeModel.generateContent(prompt);
    const content = resp.response.candidates[0].content.parts[0].text;
    const cleanJson = content.replace(/```json|```/g, '').trim();
    return JSON.parse(cleanJson);
  } catch (error) {
    console.warn('Vertex AI suggestTopics failed, using fallback:', error.message);
    const subjLower = subject.toLowerCase();
    if (subjLower.includes('phys')) {
      return [
        { topic: 'Kinematics', description: 'Study of motion of points, bodies, and systems without consideration of the forces that cause them to move.' },
        { topic: 'Newton\'s Laws of Motion', description: 'Three physical laws that together laid the foundation for classical mechanics.' },
        { topic: 'Work, Energy, and Power', description: 'Concepts of energy transfer, conservation of energy, and rate of doing work.' },
        { topic: 'Rotational Motion', description: 'Dynamics of circular motion, torque, angular momentum, and rotational inertia.' },
        { topic: 'Gravitation', description: 'Universal force of attraction acting between all matter, Kepler\'s laws of planetary motion.' }
      ];
    } else if (subjLower.includes('chem')) {
      return [
        { topic: 'Atomic Structure', description: 'The structure of atoms, electron configurations, quantum numbers, and periodic trends.' },
        { topic: 'Chemical Bonding', description: 'Ionic, covalent, and metallic bonding, molecular geometry, and intermolecular forces.' },
        { topic: 'Stoichiometry', description: 'Quantitative relationships between reactants and products in chemical reactions.' },
        { topic: 'Chemical Equilibrium', description: 'The state in which both reactants and products are present in concentrations which have no further tendency to change with time.' },
        { topic: 'Thermodynamics', description: 'Study of heat, work, energy, and the spontaneity of chemical processes.' }
      ];
    } else {
      return [
        { topic: 'Calculus', description: 'Limits, derivatives, integrals, and their applications in solving real-world rate problems.' },
        { topic: 'Linear Algebra', description: 'Systems of linear equations, matrices, vector spaces, and linear transformations.' },
        { topic: 'Probability and Statistics', description: 'Data analysis, probability distributions, hypothesis testing, and statistical inference.' },
        { topic: 'Coordinate Geometry', description: 'Study of geometry using a coordinate system, equations of lines, circles, and conics.' },
        { topic: 'Trigonometry', description: 'Relationships between angles and sides of triangles, trigonometric functions and identities.' }
      ];
    }
  }
};

