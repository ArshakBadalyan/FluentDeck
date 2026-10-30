"use strict";

/**
 * Travel role-play pack #1 — real tourist/traveler problem-solving,
 * distinct from the 10 existing travel scenarios.
 */

const { rolePlay } = require("../speaking-content-catalog");

const TRAVEL_PACK_01 = [
  rolePlay(
    "Missing a connecting flight",
    "Your first flight was delayed and you missed your connection. Talk to the airline desk about rebooking.",
    { difficultyLevel: "B1", category: "travel", userRole: "Passenger", tutorRole: "Airline agent", iconKey: "travel", order: 135,
      suggestedVocabulary: ["connecting flight", "rebook", "next available", "compensation", "delayed"] },
  ),
  rolePlay(
    "Checking in luggage that's overweight",
    "Your suitcase is over the weight limit at check-in. Decide what to do with the airline agent.",
    { difficultyLevel: "A2", category: "travel", userRole: "Passenger", tutorRole: "Check-in agent", iconKey: "travel", order: 136,
      suggestedVocabulary: ["overweight", "weight limit", "extra fee", "repack", "carry-on"] },
  ),
  rolePlay(
    "Asking a local for restaurant recommendations",
    "You're new in town and want an authentic, non-touristy place to eat. Ask a local for suggestions.",
    { difficultyLevel: "A2", category: "travel", userRole: "Tourist", tutorRole: "Local resident", iconKey: "food", order: 137,
      suggestedVocabulary: ["authentic", "recommend", "off the beaten path", "local favorite", "nearby"] },
  ),
  rolePlay(
    "Dealing with a lost passport abroad",
    "Your passport was lost or stolen while traveling. Explain the situation at your embassy and find out next steps.",
    { difficultyLevel: "B2", category: "travel", userRole: "Traveler", tutorRole: "Embassy staff", iconKey: "travel", order: 138,
      suggestedVocabulary: ["lost passport", "emergency travel document", "police report", "embassy", "replacement"] },
  ),
  rolePlay(
    "Negotiating a price for a guided tour",
    "A local guide is offering a walking tour at a high price. Negotiate a fairer rate.",
    { difficultyLevel: "B1", category: "travel", userRole: "Tourist", tutorRole: "Tour guide", iconKey: "travel", order: 139,
      suggestedVocabulary: ["negotiate", "fair price", "group rate", "duration", "included"] },
  ),
  rolePlay(
    "Renting a car at the airport",
    "You need to rent a car for a week. Ask about insurance, mileage limits, and drop-off options.",
    { difficultyLevel: "B1", category: "travel", userRole: "Customer", tutorRole: "Rental agent", iconKey: "transport", order: 140,
      suggestedVocabulary: ["rental car", "insurance coverage", "mileage limit", "drop-off", "deposit"] },
  ),
  rolePlay(
    "Asking about visa requirements at an embassy",
    "You're planning a trip and unsure if you need a visa. Ask an embassy official about the requirements.",
    { difficultyLevel: "B2", category: "travel", userRole: "Applicant", tutorRole: "Embassy official", iconKey: "school", order: 141,
      suggestedVocabulary: ["visa requirements", "tourist visa", "processing time", "documentation", "eligibility"] },
  ),
  rolePlay(
    "Complaining about a noisy hotel room",
    "Your hotel room is right next to an elevator and very noisy. Ask the front desk to move you.",
    { difficultyLevel: "B1", category: "travel", userRole: "Guest", tutorRole: "Front desk staff", iconKey: "hotel", order: 142,
      suggestedVocabulary: ["noisy", "disturb", "quieter room", "reassign", "apologize"] },
  ),
  rolePlay(
    "Getting travel insurance after an injury abroad",
    "You twisted your ankle while hiking abroad. Call your travel insurance provider to file a claim.",
    { difficultyLevel: "B2", category: "travel", userRole: "Traveler", tutorRole: "Insurance representative", iconKey: "health", order: 143,
      suggestedVocabulary: ["claim", "policy number", "medical expenses", "documentation", "reimbursement"] },
  ),
  rolePlay(
    "Asking for a table with a view",
    "You're at a restaurant and want to be seated somewhere scenic. Politely ask the host.",
    { difficultyLevel: "A2", category: "travel", userRole: "Customer", tutorRole: "Host", iconKey: "food", order: 144,
      suggestedVocabulary: ["table with a view", "available", "wait time", "seating", "prefer"] },
  ),
  rolePlay(
    "Exchanging currency at a local kiosk",
    "You need to exchange money before your trip continues. Ask about the exchange rate and fees.",
    { difficultyLevel: "A1", category: "travel", userRole: "Traveler", tutorRole: "Currency exchange clerk", iconKey: "bank", order: 145,
      suggestedVocabulary: ["exchange rate", "fee", "small bills", "how much", "currency"] },
  ),
  rolePlay(
    "Finding your way on public transit in a new city",
    "You're confused by the metro map. Ask a stranger which line and stop to take.",
    { difficultyLevel: "A2", category: "travel", userRole: "Tourist", tutorRole: "Local commuter", iconKey: "transport", order: 146,
      suggestedVocabulary: ["metro line", "transfer", "stop", "ticket", "direction"] },
  ),
  rolePlay(
    "Extending a hotel stay last minute",
    "You've decided to stay two extra nights. Ask the front desk if your room is available and the new cost.",
    { difficultyLevel: "B1", category: "travel", userRole: "Guest", tutorRole: "Front desk staff", iconKey: "hotel", order: 147,
      suggestedVocabulary: ["extend", "availability", "rate", "extra nights", "confirm"] },
  ),
  rolePlay(
    "Reporting a stolen bag to the police",
    "Your bag was stolen at a train station. File a report with local police.",
    { difficultyLevel: "B2", category: "travel", userRole: "Victim", tutorRole: "Police officer", iconKey: "travel", order: 148,
      suggestedVocabulary: ["stolen", "file a report", "description", "witness", "reference number"] },
  ),
  rolePlay(
    "Asking about food allergies at a foreign restaurant",
    "You have a severe nut allergy and the menu is in a language you don't speak well. Ask the waiter to check the ingredients.",
    { difficultyLevel: "B1", category: "travel", userRole: "Customer", tutorRole: "Waiter", iconKey: "food", order: 149,
      suggestedVocabulary: ["allergic", "ingredients", "cross-contamination", "severe", "double-check"] },
  ),
  rolePlay(
    "Joining a group tour and introducing yourself",
    "You've just joined a group tour of strangers. Introduce yourself and make small talk before it starts.",
    { difficultyLevel: "A2", category: "travel", userRole: "Tourist", tutorRole: "Fellow tourist", iconKey: "social", order: 150,
      suggestedVocabulary: ["introduce yourself", "where are you from", "first time here", "small talk", "group"] },
  ),
  rolePlay(
    "Negotiating with a street vendor",
    "You want to buy a souvenir but the price seems too high. Try to negotiate a better deal.",
    { difficultyLevel: "A2", category: "travel", userRole: "Tourist", tutorRole: "Street vendor", iconKey: "shopping", order: 151,
      suggestedVocabulary: ["too expensive", "best price", "deal", "cash", "final offer"] },
  ),
  rolePlay(
    "Dealing with a flight delay at the gate",
    "Your flight has been delayed by four hours. Ask the gate agent about the reason and your options.",
    { difficultyLevel: "B1", category: "travel", userRole: "Passenger", tutorRole: "Gate agent", iconKey: "travel", order: 152,
      suggestedVocabulary: ["delayed", "boarding time", "meal voucher", "rebook", "estimated departure"] },
  ),
  rolePlay(
    "Asking a pharmacist for medicine abroad",
    "You have a headache and cold symptoms in a country where you don't know the medicine brands. Ask the pharmacist for advice.",
    { difficultyLevel: "B1", category: "travel", userRole: "Customer", tutorRole: "Pharmacist", iconKey: "health", order: 153,
      suggestedVocabulary: ["symptoms", "over-the-counter", "dosage", "side effects", "recommend"] },
  ),
  rolePlay(
    "Checking into a hostel and meeting roommates",
    "You've just arrived at a hostel dorm room. Check in with the staff and introduce yourself to your roommates.",
    { difficultyLevel: "A2", category: "travel", userRole: "Guest", tutorRole: "Hostel staff / roommate", iconKey: "hotel", order: 154,
      suggestedVocabulary: ["dorm room", "check in", "locker", "curfew", "roommate"] },
  ),
  rolePlay(
    "Arranging airport transfer with a driver",
    "You need a ride from the airport to your hotel. Confirm the price, pickup point, and timing with a driver.",
    { difficultyLevel: "A2", category: "travel", userRole: "Passenger", tutorRole: "Driver", iconKey: "transport", order: 155,
      suggestedVocabulary: ["pickup point", "fare", "estimated time", "luggage", "confirm"] },
  ),
  rolePlay(
    "Asking locals about safety in an unfamiliar neighborhood",
    "You're staying somewhere unfamiliar and want to know which areas to avoid at night. Ask a local.",
    { difficultyLevel: "B1", category: "travel", userRole: "Traveler", tutorRole: "Local resident", iconKey: "social", order: 156,
      suggestedVocabulary: ["safe area", "avoid at night", "well-lit", "recommend", "caution"] },
  ),
  rolePlay(
    "Requesting a late check-out",
    "Your flight isn't until evening but check-out is at noon. Ask the hotel if you can stay later.",
    { difficultyLevel: "A2", category: "travel", userRole: "Guest", tutorRole: "Front desk staff", iconKey: "hotel", order: 157,
      suggestedVocabulary: ["late check-out", "flight time", "extra fee", "luggage storage", "available"] },
  ),
  rolePlay(
    "Explaining a travel emergency to a tour guide",
    "You need to leave the tour group early because of a family emergency. Explain the situation to your guide.",
    { difficultyLevel: "B2", category: "travel", userRole: "Tourist", tutorRole: "Tour guide", iconKey: "travel", order: 158,
      suggestedVocabulary: ["emergency", "leave early", "refund policy", "arrange", "understanding"] },
  ),
  rolePlay(
    "Booking a spontaneous side trip while already traveling",
    "You heard about a beautiful nearby town and want to add a day trip to your itinerary. Ask a travel agency about options.",
    { difficultyLevel: "B1", category: "travel", userRole: "Traveler", tutorRole: "Travel agent", iconKey: "travel", order: 159,
      suggestedVocabulary: ["day trip", "itinerary", "availability", "transportation", "spontaneous"] },
  ),
  rolePlay(
    "Asking for vegetarian options while traveling",
    "You're vegetarian and the menu isn't clear. Ask the server what options are available.",
    { difficultyLevel: "A1", category: "travel", userRole: "Customer", tutorRole: "Server", iconKey: "food", order: 160,
      suggestedVocabulary: ["vegetarian", "meat-free", "recommend", "ingredients", "options"] },
  ),
  rolePlay(
    "Dealing with jet lag and rescheduling plans with a travel companion",
    "You're exhausted from jet lag and want to rest instead of sightseeing today. Discuss changing plans with your travel companion.",
    { difficultyLevel: "B1", category: "travel", userRole: "Traveler", tutorRole: "Travel companion", iconKey: "social", order: 161,
      suggestedVocabulary: ["jet lag", "exhausted", "reschedule", "rest", "compromise"] },
  ),
  rolePlay(
    "Getting help after your phone dies abroad",
    "Your phone died and you need directions back to your hotel. Ask a stranger for help.",
    { difficultyLevel: "B1", category: "travel", userRole: "Tourist", tutorRole: "Stranger", iconKey: "travel", order: 162,
      suggestedVocabulary: ["phone died", "directions", "borrow", "landmark", "help me"] },
  ),
  rolePlay(
    "Discussing a travel itinerary with a travel agent",
    "You're planning a two-week trip and want expert advice on the route and pacing. Discuss it with a travel agent.",
    { difficultyLevel: "B1", category: "travel", userRole: "Client", tutorRole: "Travel agent", iconKey: "travel", order: 163,
      suggestedVocabulary: ["itinerary", "route", "pacing", "must-see", "budget"] },
  ),
  rolePlay(
    "Saying goodbye to friends made while traveling",
    "You've become close with fellow travelers over the past week and now it's time to part ways. Say goodbye and exchange contact info.",
    { difficultyLevel: "A2", category: "travel", userRole: "Traveler", tutorRole: "Fellow traveler", iconKey: "social", order: 164,
      suggestedVocabulary: ["stay in touch", "contact info", "memorable", "miss you", "until next time"] },
  ),
];

module.exports = { TRAVEL_PACK_01 };
