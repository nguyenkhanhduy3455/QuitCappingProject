import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI, Type } from '@google/genai';

export interface GeneratedTask {
  dayNumber: number;
  title: string;
  description: string;
  evidencePrompt: string;
}

@Injectable()
export class GeminiAiService {
  private readonly logger = new Logger(GeminiAiService.name);
  private readonly client: GoogleGenAI | null = null;
  private readonly apiKey: string | undefined;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (this.apiKey) {
      try {
        this.client = new GoogleGenAI({ apiKey: this.apiKey });
        this.logger.log('Gemini AI client initialized successfully.');
      } catch (err) {
        this.logger.warn(`Failed to initialize Gemini AI client: ${err.message}`);
      }
    } else {
      this.logger.warn('No GEMINI_API_KEY provided. Intelligent offline curriculum generator will be used as fallback.');
    }
  }

  async generateRoadmapTasks(
    targetGoal: string,
    currentSkillLevel: string,
    targetDuration: number,
  ): Promise<GeneratedTask[]> {
    // Clamp duration between 1 and 30 days for safety and prompt limits
    const duration = Math.min(Math.max(targetDuration, 1), 30);

    if (this.client && this.apiKey) {
      try {
        return await this.callGeminiWithSchema(targetGoal, currentSkillLevel, duration);
      } catch (error) {
        this.logger.error(`Gemini API call failed: ${error.message}. Falling back to offline generator.`, error.stack);
      }
    }

    return this.generateFallbackCurriculum(targetGoal, currentSkillLevel, duration);
  }

  private async callGeminiWithSchema(
    targetGoal: string,
    currentSkillLevel: string,
    duration: number,
  ): Promise<GeneratedTask[]> {
    const prompt = `You are QuitCapping AI, an elite anti-procrastination coach.
The user wants to achieve: "${targetGoal}"
Current Skill Level: "${currentSkillLevel}"
Target Duration: ${duration} days.

Generate a comprehensive roadmap containing 3 to 4 daily micro-tasks for EACH day from Day 1 to Day ${duration}.
CRITICAL ANTI-CHEAT REQUIREMENT:
Each micro-task MUST have a concrete, unambiguous 'evidencePrompt' describing the exact photo proof the user must capture with their phone camera to prove they actually did the task without cheating or procrastinating (e.g. 'Photo of stopwatch showing 30 mins elapsed next to your open notebook page', 'Photo of your IDE showing the passing test runner output', 'Photo of your workout gear next to today's sweat towel and gym log').

Return a JSON array of task objects matching the schema.`;

    const response = await this.client!.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.ARRAY,
          description: 'List of daily micro-tasks for the anti-procrastination roadmap',
          items: {
            type: Type.OBJECT,
            properties: {
              dayNumber: {
                type: Type.INTEGER,
                description: 'The day index of the roadmap (1 to N)',
              },
              title: {
                type: Type.STRING,
                description: 'Short, punchy action title for the micro-task',
              },
              description: {
                type: Type.STRING,
                description: 'Actionable steps to complete this micro-task',
              },
              evidencePrompt: {
                type: Type.STRING,
                description: 'Specific camera photo proof instruction to satisfy community peer-review',
              },
            },
            required: ['dayNumber', 'title', 'description', 'evidencePrompt'],
          },
        },
      },
    });

    const responseText = response.text;
    if (!responseText) {
      throw new Error('Empty response from Gemini API');
    }

    const parsed: GeneratedTask[] = JSON.parse(responseText);
    if (!Array.isArray(parsed) || parsed.length === 0) {
      throw new Error('Gemini did not return an array of tasks');
    }

    return parsed;
  }

  private generateFallbackCurriculum(
    targetGoal: string,
    currentSkillLevel: string,
    duration: number,
  ): GeneratedTask[] {
    const tasks: GeneratedTask[] = [];

    const taskTemplates = [
      {
        titleSuffix: 'Core Fundamentals & Setup',
        desc: `Lay the groundwork for "${targetGoal}". Review baseline concepts suited for ${currentSkillLevel} level.`,
        evidence: `Take a photo of your workspace or study notes with today's date written at the top.`,
      },
      {
        titleSuffix: 'Deep Work Sprint (45 mins)',
        desc: `Execute an uninterrupted 45-minute practice session focused strictly on ${targetGoal}.`,
        evidence: `Take a photo of your active timer showing 45+ minutes completed next to your work output.`,
      },
      {
        titleSuffix: 'Progress Check & Milestone Proof',
        desc: `Complete today's deliverable or exercise. Document tangible proof of what you produced.`,
        evidence: `Take a clear photo showing the actual tangible output or metric screen achieved today.`,
      },
    ];

    for (let day = 1; day <= duration; day++) {
      for (let t = 0; t < taskTemplates.length; t++) {
        const tmpl = taskTemplates[t];
        tasks.push({
          dayNumber: day,
          title: `Day ${day}: ${tmpl.titleSuffix}`,
          description: `${tmpl.desc} Focus on consistency and zero excuses.`,
          evidencePrompt: tmpl.evidence,
        });
      }
    }

    return tasks;
  }
}
