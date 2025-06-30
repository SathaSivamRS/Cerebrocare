import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.teal, title: const Text("FAQ")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            "What is CerebroCare?",
            "CerebroCare is an AI-powered cognitive rehabilitation platform designed to support individuals facing memory loss, attention difficulties, and emotional fatigue. It uses gamified training, journaling, and AI tools to assist users in their mental wellness journey.",
          ),
          _buildFAQItem(
            "Who can use CerebroCare?",
            "CerebroCare is designed for:\n"
                "- Individuals recovering from cognitive impairments (e.g., due to trauma or age).\n"
                "- Users dealing with anxiety, PTSD, ADHD, or depression.\n"
                "- Anyone looking to boost memory, focus, and emotional resilience.",
          ),
          _buildFAQItem(
            "How does CerebroCare improve memory and focus?",
            "CerebroCare provides:\n"
                "- Personalized brain training games.\n"
                "- Attention enhancement exercises.\n"
                "- AI-based journaling and mental state analysis.\n"
                "- Media-based memory recall (images, voice, video prompts).",
          ),
          _buildFAQItem(
            "What is Emotional Reconstruction?",
            "This feature helps users revisit and rebuild positive emotional memories using AI-generated prompts, past journals, and visual/audio cues to foster emotional stability and healing.",
          ),
          _buildFAQItem(
            "Is my data secure on CerebroCare?",
            "Yes. Your personal data, cognitive stats, and journal entries are stored securely using Firebase. Device-level protection and authentication are enforced, and sensitive data is never shared without consent.",
          ),
          _buildFAQItem(
            "Does CerebroCare work offline?",
            "Some basic training modules may work offline, but features like journaling analysis, emotional reconstruction, and progress tracking require an internet connection.",
          ),
          _buildFAQItem(
            "What platforms is CerebroCare available on?",
            "CerebroCare is available on Android (via Play Store) and iOS (via App Store). A web version for therapists and caregivers is in development.",
          ),
          _buildFAQItem(
            "Is CerebroCare free?",
            "Yes! CerebroCare offers a free version with access to core features. A premium version unlocks advanced personalization, additional games, and therapist integration.",
          ),
          _buildFAQItem(
            "How can I track my cognitive progress?",
            "Your dashboard shows real-time cognitive stats (Memory, Mood, Focus) updated based on your activities, journaling, and assessments.",
          ),
          _buildFAQItem(
            "How do I contact CerebroCare support?",
            "You can reach out to our team at cerebrocare.help@gmail.com for any support, suggestions, or feedback.",
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(answer, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
