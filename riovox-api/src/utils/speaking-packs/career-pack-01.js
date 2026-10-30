"use strict";

/**
 * Career role-play pack #1 — personal professional development, distinct
 * from the "business" category (which is company-to-company deal-making).
 */

const { rolePlay } = require("../speaking-content-catalog");

const CAREER_PACK_01 = [
  rolePlay(
    "Asking your manager for mentorship",
    "You admire your manager's career path and want their guidance. Ask if they'd be willing to mentor you informally.",
    { difficultyLevel: "B1", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "social", order: 105,
      suggestedVocabulary: ["mentorship", "guidance", "career path", "check in", "informal"] },
  ),
  rolePlay(
    "Negotiating a flexible work schedule",
    "You want to shift your hours to start later. Explain your reasons and propose a schedule to your manager.",
    { difficultyLevel: "B1", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 106,
      suggestedVocabulary: ["flexible hours", "core hours", "productivity", "trial period", "propose"] },
  ),
  rolePlay(
    "Explaining a resume gap in an interview",
    "You took a year off to care for a family member. Explain the gap confidently without over-apologizing.",
    { difficultyLevel: "B2", category: "career", userRole: "Candidate", tutorRole: "Interviewer", iconKey: "work", order: 107,
      suggestedVocabulary: ["employment gap", "caregiving", "confidently", "transferable skills", "ready to return"] },
  ),
  rolePlay(
    "Requesting to work from home permanently",
    "You've worked remotely for months and want it made permanent. Make your case to your manager.",
    { difficultyLevel: "B1", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 108,
      suggestedVocabulary: ["remote work", "permanent", "productivity", "in-office days", "trial"] },
  ),
  rolePlay(
    "Discussing a promotion timeline with your manager",
    "You've been in your role for two years. Ask your manager what it would take to be promoted and by when.",
    { difficultyLevel: "B2", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 109,
      suggestedVocabulary: ["promotion", "timeline", "criteria", "next level", "readiness"] },
  ),
  rolePlay(
    "Handling imposter syndrome with a mentor",
    "You feel like you don't deserve your new role. Open up to a trusted mentor and work through the feeling together.",
    { difficultyLevel: "C1", category: "career", userRole: "Employee", tutorRole: "Mentor", iconKey: "social", order: 110,
      suggestedVocabulary: ["imposter syndrome", "self-doubt", "deserve", "reassurance", "perspective"] },
  ),
  rolePlay(
    "Giving constructive feedback to a coworker",
    "A teammate's work has quality issues that are affecting the project. Give honest, kind feedback without damaging the relationship.",
    { difficultyLevel: "B2", category: "career", userRole: "Colleague", tutorRole: "Teammate", iconKey: "work", order: 111,
      suggestedVocabulary: ["constructive feedback", "specific example", "improvement", "tone", "supportive"] },
  ),
  rolePlay(
    "Receiving harsh feedback gracefully",
    "Your manager just gave you blunt criticism in front of others. Respond professionally and ask for a private follow-up.",
    { difficultyLevel: "B2", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 112,
      suggestedVocabulary: ["blunt", "professionally", "follow up", "private conversation", "composure"] },
  ),
  rolePlay(
    "Asking a colleague to stop micromanaging you",
    "A senior colleague keeps double-checking your work unnecessarily. Address it directly but diplomatically.",
    { difficultyLevel: "B2", category: "career", userRole: "Employee", tutorRole: "Senior colleague", iconKey: "work", order: 113,
      suggestedVocabulary: ["micromanage", "trust", "autonomy", "diplomatically", "boundaries"] },
  ),
  rolePlay(
    "Turning down a job offer politely",
    "You received an offer but decided to stay at your current job. Decline gracefully and keep the door open for the future.",
    { difficultyLevel: "B1", category: "career", userRole: "Candidate", tutorRole: "Recruiter", iconKey: "work", order: 114,
      suggestedVocabulary: ["decline", "grateful", "keep in touch", "not the right fit", "future opportunities"] },
  ),
  rolePlay(
    "Negotiating a signing bonus",
    "You've accepted a job offer but want a signing bonus to offset benefits you're giving up. Make the case.",
    { difficultyLevel: "B2", category: "career", userRole: "Candidate", tutorRole: "HR representative", iconKey: "work", order: 115,
      suggestedVocabulary: ["signing bonus", "offset", "unvested", "negotiate", "one-time payment"] },
  ),
  rolePlay(
    "Discussing relocation for a new role",
    "A great opportunity requires moving to another city. Talk through the pros, cons, and logistics with a career counselor.",
    { difficultyLevel: "B1", category: "career", userRole: "Employee", tutorRole: "Career counselor", iconKey: "travel", order: 116,
      suggestedVocabulary: ["relocation", "cost of living", "logistics", "uproot", "opportunity"] },
  ),
  rolePlay(
    "Asking for a second interview after rejection",
    "You were rejected for a role but believe you're a strong fit. Politely ask if there's any way to be reconsidered.",
    { difficultyLevel: "B1", category: "career", userRole: "Candidate", tutorRole: "Hiring manager", iconKey: "work", order: 117,
      suggestedVocabulary: ["reconsider", "strong fit", "respectfully", "additional information", "grateful"] },
  ),
  rolePlay(
    "Explaining why you're changing careers at 40",
    "You're switching fields entirely. Explain your motivation and transferable skills to a skeptical interviewer.",
    { difficultyLevel: "B2", category: "career", userRole: "Candidate", tutorRole: "Interviewer", iconKey: "work", order: 118,
      suggestedVocabulary: ["career change", "transferable skills", "motivation", "fresh start", "commitment"] },
  ),
  rolePlay(
    "Setting boundaries with a demanding boss",
    "Your boss expects replies to messages late at night. Explain, respectfully but firmly, why you need boundaries.",
    { difficultyLevel: "C1", category: "career", userRole: "Employee", tutorRole: "Boss", iconKey: "work", order: 119,
      suggestedVocabulary: ["boundaries", "after hours", "sustainable", "respectfully", "firm"] },
  ),
  rolePlay(
    "Requesting a title change without a raise",
    "Your responsibilities have grown but the budget for a raise isn't there yet. Ask for an updated title instead.",
    { difficultyLevel: "B2", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 120,
      suggestedVocabulary: ["title change", "responsibilities", "reflect", "budget constraints", "interim step"] },
  ),
  rolePlay(
    "Preparing for a layoff conversation as the one being let go",
    "You're about to be told your position is eliminated. Practice how you'd respond calmly and ask the right questions.",
    { difficultyLevel: "C1", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 121,
      suggestedVocabulary: ["position eliminated", "severance", "last day", "composure", "next steps"] },
  ),
  rolePlay(
    "Discussing burnout with HR",
    "You're exhausted and struggling to keep up. Explain how you're feeling to HR and ask about your options.",
    { difficultyLevel: "C1", category: "career", userRole: "Employee", tutorRole: "HR representative", iconKey: "health", order: 122,
      suggestedVocabulary: ["burnout", "workload", "mental health", "accommodations", "options"] },
  ),
  rolePlay(
    "Asking a mentor for career advice after a setback",
    "You didn't get the promotion you expected. Talk to a mentor about how to move forward.",
    { difficultyLevel: "B1", category: "career", userRole: "Mentee", tutorRole: "Mentor", iconKey: "social", order: 123,
      suggestedVocabulary: ["setback", "move forward", "perspective", "next steps", "resilience"] },
  ),
  rolePlay(
    "Negotiating remote work stipend",
    "Your company wants you back in office three days a week. Negotiate a home office stipend for the other two.",
    { difficultyLevel: "B1", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 124,
      suggestedVocabulary: ["stipend", "home office", "hybrid", "equipment", "reimbursement"] },
  ),
  rolePlay(
    "Explaining a mistake to your manager",
    "You made an error that affected a client. Tell your manager honestly, explain what happened, and propose a fix.",
    { difficultyLevel: "B1", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 125,
      suggestedVocabulary: ["mistake", "honestly", "impact", "propose a fix", "accountability"] },
  ),
  rolePlay(
    "Asking for more responsibility at work",
    "You feel ready for bigger projects. Ask your manager to give you more responsibility.",
    { difficultyLevel: "A2", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 126,
      suggestedVocabulary: ["responsibility", "ready", "bigger project", "opportunity", "capable"] },
  ),
  rolePlay(
    "Declining unpaid overtime politely",
    "Your team is asked to work an unpaid weekend. Explain politely why you can't this time.",
    { difficultyLevel: "B1", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 127,
      suggestedVocabulary: ["unpaid overtime", "prior commitment", "politely", "decline", "understand"] },
  ),
  rolePlay(
    "Discussing a lateral move to another department",
    "You're not looking for a promotion, just a change. Explain to HR why you want to move to a different team.",
    { difficultyLevel: "B2", category: "career", userRole: "Employee", tutorRole: "HR representative", iconKey: "work", order: 128,
      suggestedVocabulary: ["lateral move", "different team", "fresh challenge", "skills", "transition"] },
  ),
  rolePlay(
    "Preparing your elevator pitch at a conference",
    "You're networking at a conference and need a 30-second pitch about what you do. Practice it on a stranger.",
    { difficultyLevel: "B1", category: "career", userRole: "Attendee", tutorRole: "Fellow attendee", iconKey: "school", order: 129,
      suggestedVocabulary: ["elevator pitch", "concise", "what I do", "value", "memorable"] },
  ),
  rolePlay(
    "Handling being passed over for a promotion",
    "A colleague got the promotion you wanted. Process your disappointment and ask your manager for honest feedback.",
    { difficultyLevel: "C1", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 130,
      suggestedVocabulary: ["passed over", "disappointment", "honest feedback", "growth areas", "next opportunity"] },
  ),
  rolePlay(
    "Asking for a reference from a former manager",
    "You're job hunting and want to use a former manager as a reference. Reach out and ask.",
    { difficultyLevel: "A2", category: "career", userRole: "Former employee", tutorRole: "Former manager", iconKey: "social", order: 131,
      suggestedVocabulary: ["reference", "job hunting", "would you mind", "reach out", "appreciate"] },
  ),
  rolePlay(
    "Negotiating parental leave with HR",
    "You're expecting a child and want to understand and negotiate your leave options.",
    { difficultyLevel: "B2", category: "career", userRole: "Employee", tutorRole: "HR representative", iconKey: "work", order: 132,
      suggestedVocabulary: ["parental leave", "paid leave", "return date", "coverage plan", "options"] },
  ),
  rolePlay(
    "Explaining why you're leaving after a short tenure",
    "You're resigning after only six months. Explain your reasons professionally in an exit interview.",
    { difficultyLevel: "B2", category: "career", userRole: "Employee", tutorRole: "HR representative", iconKey: "work", order: 133,
      suggestedVocabulary: ["short tenure", "exit interview", "not the right fit", "professionally", "resign"] },
  ),
  rolePlay(
    "Discussing a return-to-office mandate with your manager",
    "The company just announced everyone must return to the office full-time. Voice your concerns to your manager.",
    { difficultyLevel: "B2", category: "career", userRole: "Employee", tutorRole: "Manager", iconKey: "work", order: 134,
      suggestedVocabulary: ["mandate", "return to office", "concerns", "commute", "compromise"] },
  ),
];

module.exports = { CAREER_PACK_01 };
