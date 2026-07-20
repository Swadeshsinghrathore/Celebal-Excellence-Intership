"""
CityReads Dataset Generator
============================
Generates realistic, production-like data for the CityReads analytics platform.
Tables: books, customers, orders, loans, reviews

Design principles:
  - Real Indian names, cities, book titles, authors
  - Realistic temporal patterns (weekend spikes, festival seasons, morning/evening peaks)
  - Business-realistic distributions (power-law popularity, membership tiers, churn)
  - Controlled noise: duplicate rows, NULLs in optional fields, invalid FKs, bad ratings,
    out-of-range quantities, wrong status values — mimicking real OLTP dirt
  - Correlations: popular books get more reviews & loans; premium members spend more
"""

import random
import csv
import os
import math
from datetime import datetime, date, timedelta
from collections import defaultdict

random.seed(42)

# ── Output directory ──────────────────────────────────────────────────────────
OUT_DIR = "cityreads_dataset"
os.makedirs(OUT_DIR, exist_ok=True)

# ── Config ────────────────────────────────────────────────────────────────────
START_DATE = date(2020, 1, 1)
END_DATE   = date(2024, 12, 31)
N_BOOKS       = 320
N_CUSTOMERS   = 2800
N_ORDERS      = 28000
N_LOANS       = 9500
N_REVIEWS     = 7200

NOISE_DUPLICATE_RATE  = 0.012   # ~1.2% duplicate rows injected
NOISE_NULL_RATE       = 0.025   # ~2.5% optional fields randomly nulled
NOISE_INVALID_RATE    = 0.018   # ~1.8% rows with bad values

# ── Real data pools ───────────────────────────────────────────────────────────

FIRST_NAMES = [
    "Aarav","Vivaan","Aditya","Vihaan","Arjun","Sai","Reyansh","Ayaan","Krishna","Ishaan",
    "Shaurya","Atharva","Advaith","Dhruv","Kabir","Ritvik","Aadhav","Pranav","Siddharth","Rudra",
    "Ananya","Diya","Saanvi","Aanya","Aadhya","Kiara","Pari","Navya","Angel","Nisha",
    "Priya","Meera","Kavya","Ishita","Avni","Riya","Shreya","Pooja","Tanvi","Swara",
    "Rahul","Rohit","Amit","Vikram","Suresh","Rajesh","Nikhil","Gaurav","Varun","Karan",
    "Deepak","Manish","Anil","Sundar","Ramesh","Harish","Girish","Prakash","Santosh","Vinod",
    "Lakshmi","Sunita","Geeta","Radha","Savita","Kamala","Usha","Rekha","Sushma","Vandana",
    "Aryan","Aakash","Parth","Yash","Rohan","Kunal","Mihir","Dev","Harsh","Neil",
    "Zara","Aisha","Sara","Fatima","Nadia","Laila","Hira","Sana","Ruhi","Aliya",
    "Tushar","Pranit","Omkar","Chinmay","Shubham","Prasad","Tejas","Nitin","Sachin","Ajay",
    "Bhavna","Chetna","Dipali","Ekta","Falak","Garima","Himani","Isha","Jyoti","Komal",
]

LAST_NAMES = [
    "Sharma","Verma","Singh","Kumar","Patel","Shah","Gupta","Mehta","Joshi","Nair",
    "Reddy","Rao","Iyer","Pillai","Menon","Chatterjee","Banerjee","Mukherjee","Das","Bose",
    "Mishra","Tiwari","Pandey","Shukla","Tripathi","Dubey","Yadav","Chauhan","Thakur","Rajput",
    "Agarwal","Garg","Mittal","Jain","Khanna","Kapoor","Malhotra","Chopra","Bhatia","Sethi",
    "Sinha","Saxena","Srivastava","Chaturvedi","Dwivedi","Upadhyay","Bajpai","Awasthi","Dixit","Vyas",
    "Desai","Parikh","Modi","Trivedi","Bhatt","Kulkarni","Deshpande","Patil","Jadhav","Mane",
    "Krishnan","Venkatesh","Subramaniam","Narayanan","Rajan","Sundaram","Balaji","Anand","Raman","Murthy",
    "Choudhary","Bhaduri","Chakraborty","Ghosh","Sen","Roy","Dey","Mondal","Sarkar","Biswas",
]

CITIES = [
    # Tier-1 (high weight)
    "Mumbai","Delhi","Bengaluru","Hyderabad","Chennai","Kolkata","Pune","Ahmedabad",
    # Tier-2
    "Jaipur","Lucknow","Kanpur","Nagpur","Indore","Bhopal","Patna","Surat","Vadodara","Coimbatore",
    "Kochi","Chandigarh","Guwahati","Bhubaneswar","Thiruvananthapuram","Visakhapatnam","Nashik","Aurangabad",
    # Tier-3
    "Jodhpur","Udaipur","Ajmer","Kota","Bikaner","Sikar","Alwar","Bharatpur","Pali","Chittorgarh",
    "Varanasi","Agra","Meerut","Allahabad","Ghaziabad","Noida","Faridabad","Gurugram","Ambala","Rohtak",
    "Mysuru","Mangaluru","Hubballi","Belagavi","Shivamogga","Tumakuru","Davangere","Vijayawada","Guntur",
    "Madurai","Tiruchirappalli","Salem","Vellore","Erode","Tirunelveli","Raipur","Ranchi","Dhanbad",
]

CITY_WEIGHTS = (
    [120]*8 +   # Tier-1
    [55]*18 +   # Tier-2
    [18]*38     # Tier-3
)

# Realistic book catalogue
BOOKS_DATA = [
    # (title, author, genre, base_price)
    # FICTION
    ("The God of Small Things", "Arundhati Roy", "Fiction", 399),
    ("A Fine Balance", "Rohinton Mistry", "Fiction", 449),
    ("The White Tiger", "Aravind Adiga", "Fiction", 329),
    ("Midnight's Children", "Salman Rushdie", "Fiction", 549),
    ("The Namesake", "Jhumpa Lahiri", "Fiction", 379),
    ("Train to Pakistan", "Khushwant Singh", "Fiction", 299),
    ("Interpreter of Maladies", "Jhumpa Lahiri", "Fiction", 349),
    ("The Palace of Illusions", "Chitra Banerjee Divakaruni", "Fiction", 399),
    ("A Suitable Boy", "Vikram Seth", "Fiction", 699),
    ("The Shadow Lines", "Amitav Ghosh", "Fiction", 349),
    ("The Glass Palace", "Amitav Ghosh", "Fiction", 449),
    ("English, August", "Upamanyu Chatterjee", "Fiction", 299),
    ("Swami and Friends", "R.K. Narayan", "Fiction", 249),
    ("Malgudi Days", "R.K. Narayan", "Fiction", 279),
    ("The Guide", "R.K. Narayan", "Fiction", 259),
    ("Untouchable", "Mulk Raj Anand", "Fiction", 199),
    ("Coolie", "Mulk Raj Anand", "Fiction", 229),
    ("Raag Darbari", "Shrilal Shukla", "Fiction", 349),
    ("Godan", "Munshi Premchand", "Fiction", 299),
    ("Nirmala", "Munshi Premchand", "Fiction", 249),
    ("The Inheritance of Loss", "Kiran Desai", "Fiction", 399),
    ("Hullabaloo in the Guava Orchard", "Kiran Desai", "Fiction", 329),
    ("The Space Between Us", "Thrity Umrigar", "Fiction", 379),
    ("Such a Long Journey", "Rohinton Mistry", "Fiction", 399),
    ("Family Matters", "Rohinton Mistry", "Fiction", 419),
    ("The Rozabal Line", "Ashwin Sanghi", "Fiction", 349),
    ("Chanakya's Chant", "Ashwin Sanghi", "Fiction", 379),
    ("The Krishna Key", "Ashwin Sanghi", "Fiction", 399),
    ("Immortals of Meluha", "Amish Tripathi", "Fiction", 349),
    ("The Secret of the Nagas", "Amish Tripathi", "Fiction", 349),
    ("The Oath of the Vayuputras", "Amish Tripathi", "Fiction", 349),
    ("Scion of Ikshvaku", "Amish Tripathi", "Fiction", 329),
    ("Ram - Scion of Ikshvaku", "Amish Tripathi", "Fiction", 349),
    ("Five Point Someone", "Chetan Bhagat", "Fiction", 199),
    ("One Night at the Call Center", "Chetan Bhagat", "Fiction", 199),
    ("The 3 Mistakes of My Life", "Chetan Bhagat", "Fiction", 199),
    ("2 States", "Chetan Bhagat", "Fiction", 199),
    ("Revolution 2020", "Chetan Bhagat", "Fiction", 199),
    ("Half Girlfriend", "Chetan Bhagat", "Fiction", 199),
    ("The Girl on the Train", "Paula Hawkins", "Fiction", 399),
    ("Gone Girl", "Gillian Flynn", "Fiction", 429),
    ("The Da Vinci Code", "Dan Brown", "Fiction", 449),
    ("Angels and Demons", "Dan Brown", "Fiction", 429),
    ("Inferno", "Dan Brown", "Fiction", 449),
    ("The Alchemist", "Paulo Coelho", "Fiction", 299),
    ("Eleven Minutes", "Paulo Coelho", "Fiction", 279),
    ("Veronika Decides to Die", "Paulo Coelho", "Fiction", 269),
    ("Eat Pray Love", "Elizabeth Gilbert", "Fiction", 379),
    ("The Kite Runner", "Khaled Hosseini", "Fiction", 399),
    ("A Thousand Splendid Suns", "Khaled Hosseini", "Fiction", 399),
    ("To Kill a Mockingbird", "Harper Lee", "Fiction", 349),
    ("1984", "George Orwell", "Fiction", 279),
    ("Animal Farm", "George Orwell", "Fiction", 199),
    ("Brave New World", "Aldous Huxley", "Fiction", 299),
    ("The Catcher in the Rye", "J.D. Salinger", "Fiction", 299),
    ("Of Mice and Men", "John Steinbeck", "Fiction", 249),
    ("The Great Gatsby", "F. Scott Fitzgerald", "Fiction", 279),
    ("Pride and Prejudice", "Jane Austen", "Fiction", 249),
    ("Sense and Sensibility", "Jane Austen", "Fiction", 229),
    ("Jane Eyre", "Charlotte Bronte", "Fiction", 269),
    # SCIENCE
    ("A Brief History of Time", "Stephen Hawking", "Science", 499),
    ("The Grand Design", "Stephen Hawking", "Science", 549),
    ("Cosmos", "Carl Sagan", "Science", 599),
    ("The Selfish Gene", "Richard Dawkins", "Science", 449),
    ("The God Delusion", "Richard Dawkins", "Science", 499),
    ("Sapiens", "Yuval Noah Harari", "Science", 599),
    ("Homo Deus", "Yuval Noah Harari", "Science", 599),
    ("21 Lessons for the 21st Century", "Yuval Noah Harari", "Science", 549),
    ("Thinking Fast and Slow", "Daniel Kahneman", "Science", 649),
    ("Predictably Irrational", "Dan Ariely", "Science", 499),
    ("The Black Swan", "Nassim Nicholas Taleb", "Science", 649),
    ("Antifragile", "Nassim Nicholas Taleb", "Science", 699),
    ("The Innovator's Dilemma", "Clayton Christensen", "Science", 599),
    ("Zero to One", "Peter Thiel", "Science", 549),
    ("The Lean Startup", "Eric Ries", "Science", 499),
    ("Outliers", "Malcolm Gladwell", "Science", 449),
    ("The Tipping Point", "Malcolm Gladwell", "Science", 429),
    ("Blink", "Malcolm Gladwell", "Science", 429),
    ("Freakonomics", "Steven Levitt & Stephen Dubner", "Science", 449),
    ("SuperFreakonomics", "Steven Levitt & Stephen Dubner", "Science", 399),
    ("The Sixth Extinction", "Elizabeth Kolbert", "Science", 549),
    ("Silent Spring", "Rachel Carson", "Science", 399),
    ("The Double Helix", "James D. Watson", "Science", 449),
    ("The Emperor of All Maladies", "Siddhartha Mukherjee", "Science", 649),
    ("The Gene", "Siddhartha Mukherjee", "Science", 699),
    ("Being Mortal", "Atul Gawande", "Science", 499),
    ("The Checklist Manifesto", "Atul Gawande", "Science", 449),
    ("Surely You're Joking Mr. Feynman", "Richard Feynman", "Science", 499),
    ("What Do You Care What Other People Think", "Richard Feynman", "Science", 449),
    ("A Short History of Nearly Everything", "Bill Bryson", "Science", 549),
    # NON-FICTION
    ("Wings of Fire", "A.P.J. Abdul Kalam", "Non-fiction", 199),
    ("Ignited Minds", "A.P.J. Abdul Kalam", "Non-fiction", 199),
    ("My Experiments with Truth", "Mahatma Gandhi", "Non-fiction", 249),
    ("The Discovery of India", "Jawaharlal Nehru", "Non-fiction", 399),
    ("India After Gandhi", "Ramachandra Guha", "Non-fiction", 699),
    ("Gandhi Before India", "Ramachandra Guha", "Non-fiction", 649),
    ("An Era of Darkness", "Shashi Tharoor", "Non-fiction", 499),
    ("Inglorious Empire", "Shashi Tharoor", "Non-fiction", 449),
    ("The Argumentative Indian", "Amartya Sen", "Non-fiction", 549),
    ("Poverty and Famines", "Amartya Sen", "Non-fiction", 649),
    ("Losing My Virginity", "Richard Branson", "Non-fiction", 499),
    ("Steve Jobs", "Walter Isaacson", "Non-fiction", 749),
    ("Elon Musk", "Walter Isaacson", "Non-fiction", 849),
    ("Einstein: His Life and Universe", "Walter Isaacson", "Non-fiction", 699),
    ("Leonardo da Vinci", "Walter Isaacson", "Non-fiction", 799),
    ("Open", "Andre Agassi", "Non-fiction", 499),
    ("Playing It My Way", "Sachin Tendulkar", "Non-fiction", 599),
    ("The Test of My Life", "Yuvraj Singh", "Non-fiction", 399),
    ("Straight Drive", "Sourav Ganguly", "Non-fiction", 449),
    ("Born a Crime", "Trevor Noah", "Non-fiction", 449),
    ("Becoming", "Michelle Obama", "Non-fiction", 699),
    ("A Promised Land", "Barack Obama", "Non-fiction", 799),
    ("The Diary of a Young Girl", "Anne Frank", "Non-fiction", 299),
    ("Long Walk to Freedom", "Nelson Mandela", "Non-fiction", 649),
    ("Man's Search for Meaning", "Viktor Frankl", "Non-fiction", 299),
    ("Educated", "Tara Westover", "Non-fiction", 499),
    ("When Breath Becomes Air", "Paul Kalanithi", "Non-fiction", 449),
    ("The Glass Castle", "Jeannette Walls", "Non-fiction", 429),
    ("I Am Malala", "Malala Yousafzai", "Non-fiction", 399),
    ("Permanent Record", "Edward Snowden", "Non-fiction", 549),
    # SELF-HELP
    ("The 7 Habits of Highly Effective People", "Stephen Covey", "Self-Help", 449),
    ("How to Win Friends and Influence People", "Dale Carnegie", "Self-Help", 299),
    ("Think and Grow Rich", "Napoleon Hill", "Self-Help", 249),
    ("Rich Dad Poor Dad", "Robert Kiyosaki", "Self-Help", 299),
    ("The Richest Man in Babylon", "George S. Clason", "Self-Help", 199),
    ("Atomic Habits", "James Clear", "Self-Help", 499),
    ("Deep Work", "Cal Newport", "Self-Help", 449),
    ("Digital Minimalism", "Cal Newport", "Self-Help", 429),
    ("So Good They Can't Ignore You", "Cal Newport", "Self-Help", 399),
    ("Mindset", "Carol S. Dweck", "Self-Help", 449),
    ("Grit", "Angela Duckworth", "Self-Help", 449),
    ("Drive", "Daniel H. Pink", "Self-Help", 429),
    ("The Power of Habit", "Charles Duhigg", "Self-Help", 449),
    ("Smarter Faster Better", "Charles Duhigg", "Self-Help", 429),
    ("The Subtle Art of Not Giving a F*ck", "Mark Manson", "Self-Help", 399),
    ("Everything Is F*cked", "Mark Manson", "Self-Help", 399),
    ("The 4-Hour Workweek", "Tim Ferriss", "Self-Help", 499),
    ("Tools of Titans", "Tim Ferriss", "Self-Help", 699),
    ("Start with Why", "Simon Sinek", "Self-Help", 399),
    ("Leaders Eat Last", "Simon Sinek", "Self-Help", 429),
    ("The Infinite Game", "Simon Sinek", "Self-Help", 449),
    ("Ikigai", "Hector Garcia & Francesc Miralles", "Self-Help", 299),
    ("The 5 AM Club", "Robin Sharma", "Self-Help", 349),
    ("The Monk Who Sold His Ferrari", "Robin Sharma", "Self-Help", 299),
    ("Who Moved My Cheese", "Spencer Johnson", "Self-Help", 199),
    ("The One Minute Manager", "Kenneth Blanchard", "Self-Help", 249),
    ("Awaken the Giant Within", "Tony Robbins", "Self-Help", 549),
    ("Unlimited Power", "Tony Robbins", "Self-Help", 499),
    ("The Power of Now", "Eckhart Tolle", "Self-Help", 349),
    ("A New Earth", "Eckhart Tolle", "Self-Help", 369),
    # MYSTERY
    ("Murder on the Orient Express", "Agatha Christie", "Mystery", 299),
    ("And Then There Were None", "Agatha Christie", "Mystery", 279),
    ("The Murder of Roger Ackroyd", "Agatha Christie", "Mystery", 289),
    ("Death on the Nile", "Agatha Christie", "Mystery", 299),
    ("The Hound of the Baskervilles", "Arthur Conan Doyle", "Mystery", 249),
    ("A Study in Scarlet", "Arthur Conan Doyle", "Mystery", 229),
    ("The Sign of the Four", "Arthur Conan Doyle", "Mystery", 239),
    ("The Big Sleep", "Raymond Chandler", "Mystery", 279),
    ("The Maltese Falcon", "Dashiell Hammett", "Mystery", 269),
    ("In the Woods", "Tana French", "Mystery", 399),
    ("The Dublin Murder Squad", "Tana French", "Mystery", 429),
    ("The Girl with the Dragon Tattoo", "Stieg Larsson", "Mystery", 449),
    ("The Girl Who Played with Fire", "Stieg Larsson", "Mystery", 449),
    ("The Girl Who Kicked the Hornet's Nest", "Stieg Larsson", "Mystery", 449),
    ("The No. 1 Ladies Detective Agency", "Alexander McCall Smith", "Mystery", 349),
    ("Big Little Lies", "Liane Moriarty", "Mystery", 399),
    ("Nine Perfect Strangers", "Liane Moriarty", "Mystery", 419),
    ("The Woman in the Window", "A.J. Finn", "Mystery", 399),
    ("Sharp Objects", "Gillian Flynn", "Mystery", 379),
    ("Dark Places", "Gillian Flynn", "Mystery", 379),
    # HISTORY
    ("The Story of Civilisation Vol 1", "Will Durant", "History", 799),
    ("The Rise and Fall of the Third Reich", "William L. Shirer", "History", 849),
    ("Guns Germs and Steel", "Jared Diamond", "History", 649),
    ("The Silk Roads", "Peter Frankopan", "History", 699),
    ("SPQR: A History of Ancient Rome", "Mary Beard", "History", 599),
    ("The Anarchy", "William Dalrymple", "History", 699),
    ("Return of a King", "William Dalrymple", "History", 649),
    ("White Mughals", "William Dalrymple", "History", 599),
    ("City of Djinns", "William Dalrymple", "History", 499),
    ("The Last Mughal", "William Dalrymple", "History", 649),
    ("Empire of the Moghul", "Alex Rutherford", "History", 549),
    ("The Great Partition", "Yasmin Khan", "History", 549),
    ("Freedom at Midnight", "Larry Collins & Dominique Lapierre", "History", 499),
    ("The Age of Extremes", "Eric Hobsbawm", "History", 649),
    ("The Origins of Totalitarianism", "Hannah Arendt", "History", 699),
    ("The Crusades", "Thomas Asbridge", "History", 649),
    ("Alexander the Great", "Philip Freeman", "History", 499),
    ("Caesar", "Adrian Goldsworthy", "History", 549),
    ("Napoleon", "Andrew Roberts", "History", 799),
    ("Churchill", "Roy Jenkins", "History", 749),
]

EMAIL_DOMAINS = [
    "gmail.com", "gmail.com", "gmail.com",   # gmail heavy weight
    "yahoo.com", "yahoo.co.in",
    "hotmail.com", "outlook.com",
    "rediffmail.com", "ymail.com",
]

MEMBERSHIPS = ["BASIC", "BASIC", "BASIC", "BASIC", "PREMIUM", "PREMIUM", "LIBRARY"]

ORDER_STATUSES = {
    "DELIVERED":  0.68,
    "SHIPPED":    0.12,
    "PENDING":    0.10,
    "CANCELLED":  0.10,
}

# ── Utility functions ─────────────────────────────────────────────────────────

def weighted_choice(items, weights):
    total = sum(weights)
    r = random.uniform(0, total)
    upto = 0
    for item, w in zip(items, weights):
        upto += w
        if r <= upto:
            return item
    return items[-1]

def rand_date(start: date, end: date) -> date:
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))

def rand_date_weighted(start: date, end: date) -> date:
    """
    Generates dates with realistic spikes:
      - Higher volume Oct–Dec (festive season: Dussehra, Diwali, Christmas)
      - Lower volume Feb–Mar
      - Slight weekend bump applied at order level
    """
    while True:
        d = rand_date(start, end)
        month_weights = {
            1: 0.8, 2: 0.65, 3: 0.7, 4: 0.75, 5: 0.8,
            6: 0.85, 7: 0.85, 8: 0.9, 9: 0.95, 10: 1.3,
            11: 1.4, 12: 1.5
        }
        if random.random() < month_weights.get(d.month, 1.0):
            return d

def rand_datetime(d: date) -> datetime:
    """Realistic hour distribution — morning and evening peaks."""
    hour_weights = [
        1,1,1,1,1,2,    # 0–5
        4,7,9,8,7,8,    # 6–11
        9,7,6,6,7,10,   # 12–17
        12,11,9,7,4,2   # 18–23
    ]
    hour = weighted_choice(list(range(24)), hour_weights)
    minute = random.randint(0, 59)
    second = random.randint(0, 59)
    return datetime(d.year, d.month, d.day, hour, minute, second)

def make_email(name: str, existing: set) -> str:
    parts = name.lower().split()
    base_options = [
        f"{''.join(parts)}",
        f"{parts[0]}.{parts[-1]}",
        f"{parts[0]}{parts[-1][0]}",
        f"{parts[-1]}.{parts[0]}",
        f"{parts[0]}_{random.randint(1,99)}",
    ]
    domain = random.choice(EMAIL_DOMAINS)
    for base in base_options:
        base = base.replace(" ", "").replace("'", "")
        candidate = f"{base}@{domain}"
        if candidate not in existing:
            existing.add(candidate)
            return candidate
    # fallback with random suffix
    candidate = f"{parts[0]}{random.randint(100,9999)}@{domain}"
    existing.add(candidate)
    return candidate

def power_law_popularity(n: int, exponent: float = 1.8) -> list:
    """Returns weights following a power-law (Zipf-like) distribution."""
    weights = [1.0 / (i ** exponent) for i in range(1, n + 1)]
    total = sum(weights)
    return [w / total for w in weights]

def review_text_generator(rating: int, genre: str) -> str:
    """Generates plausible, varied review text matching the rating."""
    positive = [
        "Absolutely loved this book — couldn't put it down!",
        "One of the best reads I have had in years. Highly recommended.",
        "The writing is exceptional and the story gripped me from page one.",
        "A masterpiece. Every chapter left me wanting more.",
        "Brilliant narrative. The characters feel genuinely real.",
        "This book changed the way I think. A must-read for everyone.",
        "Beautifully written. The author's style is simply stunning.",
        "I finished this in two sittings. Absolutely riveting.",
        "Perfect blend of story and insight. Will read again.",
        "Exceeded all my expectations. Truly extraordinary.",
    ]
    good = [
        "A very good read overall. Some chapters were slow but worth it.",
        "Enjoyed it quite a bit. Solid writing and interesting ideas.",
        "Good book, though the ending felt a little rushed.",
        "Liked it. The first half is stronger than the second.",
        "Well-written and engaging. A few plot holes but forgivable.",
        "Above average. Would recommend to fans of the genre.",
        "Pleasant read. Nothing groundbreaking but definitely enjoyable.",
        "Mostly great. The middle section drags a bit.",
    ]
    neutral = [
        "Decent read. Not my favourite but not bad either.",
        "Average. Had its moments but failed to really engage me.",
        "It was okay. The hype around this book is a bit overstated.",
        "Some interesting parts, but overall felt underwhelming.",
        "Mixed feelings. Good premise, mediocre execution.",
        "Neither great nor terrible. Passes the time.",
        "Had potential but did not quite deliver on its promise.",
    ]
    negative = [
        "Disappointed. Expected much more based on the reviews.",
        "Struggled to get through it. The story meanders endlessly.",
        "Not for me. The writing style felt very dated.",
        "Overrated. I did not enjoy the characters at all.",
        "The plot felt disjointed and the pacing was off throughout.",
        "Would not recommend. Too slow and the payoff was not worth it.",
    ]
    very_negative = [
        "Could not finish it. Extremely boring.",
        "Terrible. Wasted my money and my time.",
        "One of the worst books I have read. No coherent plot.",
        "Gave up halfway. The writing is unbearable.",
        "Do not waste your money on this.",
    ]
    if rating == 5:
        return random.choice(positive)
    elif rating == 4:
        return random.choice(good)
    elif rating == 3:
        return random.choice(neutral)
    elif rating == 2:
        return random.choice(negative)
    else:
        return random.choice(very_negative)

# ── 1. Generate BOOKS ─────────────────────────────────────────────────────────

def generate_books():
    print("Generating books...")
    rows = []
    used_titles = set()
    book_pool = BOOKS_DATA.copy()
    random.shuffle(book_pool)

    for i, (title, author, genre, base_price) in enumerate(book_pool[:N_BOOKS], start=1):
        if title in used_titles:
            title = f"{title} (Revised Edition)"
        used_titles.add(title)

        # Price variation: ±15%
        price = round(base_price * random.uniform(0.85, 1.15), 2)
        # Stock: power-law — bestsellers have higher stock
        stock = random.choices(
            [0, 1, 2, 3, 5, 8, 12, 20, 35, 50, 75, 100],
            weights=[2, 4, 6, 8, 10, 12, 15, 18, 12, 8, 4, 2]
        )[0]
        # Realistic published_on: older classics stay old, new books ~2015–2024
        if base_price < 300:
            pub = rand_date(date(1960, 1, 1), date(2015, 12, 31))
        else:
            pub = rand_date(date(1980, 1, 1), date(2024, 1, 1))

        rows.append({
            "book_id": i,
            "title": title,
            "author": author,
            "genre": genre,
            "price": price,
            "stock": stock,
            "published_on": pub.strftime("%Y-%m-%d"),
        })
    return rows

# ── 2. Generate CUSTOMERS ─────────────────────────────────────────────────────

def generate_customers():
    print("Generating customers...")
    rows = []
    used_emails = set()

    for i in range(1, N_CUSTOMERS + 1):
        fname = random.choice(FIRST_NAMES)
        lname = random.choice(LAST_NAMES)
        name = f"{fname} {lname}"
        email = make_email(name, used_emails)
        city = weighted_choice(CITIES, CITY_WEIGHTS)
        joined = rand_date(date(2019, 1, 1), date(2024, 10, 1))
        membership = random.choice(MEMBERSHIPS)

        rows.append({
            "customer_id": i,
            "name": name,
            "email": email,
            "city": city,
            "joined_on": joined.strftime("%Y-%m-%d"),
            "membership": membership,
        })
    return rows

# ── 3. Generate ORDERS ────────────────────────────────────────────────────────

def generate_orders(books, customers):
    print("Generating orders...")

    # Popularity weights for books (power-law — some books dominate)
    book_ids = [b["book_id"] for b in books]
    book_pop  = power_law_popularity(len(book_ids), exponent=1.6)
    book_price = {b["book_id"]: b["price"] for b in books}

    # PREMIUM members order 3x more; LIBRARY members rarely buy
    def customer_order_weight(c):
        if c["membership"] == "PREMIUM":
            return 3.0
        elif c["membership"] == "LIBRARY":
            return 0.4
        return 1.0

    customer_ids = [c["customer_id"] for c in customers]
    customer_joined = {c["customer_id"]: date.fromisoformat(c["joined_on"]) for c in customers}
    cust_weights = [customer_order_weight(c) for c in customers]

    rows = []
    order_id = 1

    for _ in range(N_ORDERS):
        cust_id = weighted_choice(customer_ids, cust_weights)
        book_id = weighted_choice(book_ids, book_pop)

        # Order must be after customer joined
        earliest = max(customer_joined[cust_id], START_DATE)
        if earliest >= END_DATE:
            earliest = END_DATE - timedelta(days=30)
        order_date = rand_date_weighted(earliest, END_DATE)

        # Quantity: mostly 1, occasionally 2-5, rarely more
        quantity = random.choices([1,2,3,4,5,6,8,10], weights=[60,20,8,4,3,2,2,1])[0]

        # Status weighted by recency — recent orders more likely PENDING/SHIPPED
        days_ago = (END_DATE - order_date).days
        if days_ago < 7:
            status = random.choices(["PENDING","SHIPPED","DELIVERED","CANCELLED"], [40,30,20,10])[0]
        elif days_ago < 30:
            status = random.choices(["PENDING","SHIPPED","DELIVERED","CANCELLED"], [15,25,50,10])[0]
        else:
            status = random.choices(["PENDING","SHIPPED","DELIVERED","CANCELLED"], [5,7,78,10])[0]

        rows.append({
            "order_id": order_id,
            "customer_id": cust_id,
            "book_id": book_id,
            "order_date": order_date.strftime("%Y-%m-%d"),
            "quantity": quantity,
            "status": status,
        })
        order_id += 1

    return rows

# ── 4. Generate LOANS ─────────────────────────────────────────────────────────

def generate_loans(books, customers):
    print("Generating loans...")

    # Only LIBRARY and some PREMIUM members borrow
    eligible = [c for c in customers if c["membership"] in ("LIBRARY", "PREMIUM", "BASIC")]
    lib_customers = [c for c in customers if c["membership"] == "LIBRARY"]
    premium_customers = [c for c in customers if c["membership"] == "PREMIUM"]
    basic_customers = [c for c in customers if c["membership"] == "BASIC"]

    pool = lib_customers * 6 + premium_customers * 2 + basic_customers
    random.shuffle(pool)

    book_ids  = [b["book_id"] for b in books]
    book_pop  = power_law_popularity(len(book_ids), exponent=1.5)
    customer_joined = {c["customer_id"]: date.fromisoformat(c["joined_on"]) for c in customers}

    rows = []
    loan_id = 1

    for _ in range(N_LOANS):
        cust = random.choice(pool)
        cust_id = cust["customer_id"]
        book_id = weighted_choice(book_ids, book_pop)

        earliest = max(customer_joined[cust_id], START_DATE)
        if earliest >= END_DATE:
            earliest = END_DATE - timedelta(days=60)
        loan_date = rand_date(earliest, END_DATE - timedelta(days=5))

        # Loan period: 14 days standard, occasionally 21
        loan_days = random.choices([14, 14, 14, 21], weights=[5, 5, 5, 2])[0]
        due_date = loan_date + timedelta(days=loan_days)

        # Return behaviour: correlated with membership
        r = random.random()
        if cust["membership"] == "LIBRARY":
            return_prob = 0.88   # library members mostly return
        elif cust["membership"] == "PREMIUM":
            return_prob = 0.80
        else:
            return_prob = 0.72

        if loan_date > END_DATE - timedelta(days=21):
            # Very recent loans — many still out
            return_date = None
        elif r < return_prob * 0.75:
            # Returned on time
            days_early = random.randint(0, max(0, loan_days - 1))
            return_date = due_date - timedelta(days=days_early)
        elif r < return_prob:
            # Returned late — mild
            return_date = due_date + timedelta(days=random.randint(1, 7))
        elif r < return_prob + 0.06:
            # Returned severely late
            return_date = due_date + timedelta(days=random.randint(8, 45))
        else:
            # Not returned (NULL)
            return_date = None

        rows.append({
            "loan_id": loan_id,
            "customer_id": cust_id,
            "book_id": book_id,
            "loan_date": loan_date.strftime("%Y-%m-%d"),
            "due_date": due_date.strftime("%Y-%m-%d"),
            "return_date": return_date.strftime("%Y-%m-%d") if return_date else "",
        })
        loan_id += 1

    return rows

# ── 5. Generate REVIEWS ───────────────────────────────────────────────────────

def generate_reviews(books, customers, orders):
    print("Generating reviews...")

    # Only DELIVERED orders can generate reviews; subset of them do
    delivered = [o for o in orders if o["status"] == "DELIVERED"]
    random.shuffle(delivered)

    book_avg_rating = {}  # track realistic per-book averages
    # Assign each book a "true quality" score used to bias ratings
    book_quality = {}
    for b in books:
        # Quality influenced by genre (Science/History slightly higher avg)
        base = 3.5
        if b["genre"] in ("Science", "History", "Non-fiction"):
            base = 3.8
        book_quality[b["book_id"]] = random.gauss(base, 0.5)
        book_quality[b["book_id"]] = max(1.5, min(5.0, book_quality[b["book_id"]]))

    customer_joined = {c["customer_id"]: date.fromisoformat(c["joined_on"]) for c in customers}

    rows = []
    used_pairs = set()   # (customer_id, book_id) — one review per pair
    review_id = 1

    sampled = random.sample(delivered, min(N_REVIEWS + 500, len(delivered)))

    for order in sampled:
        if review_id > N_REVIEWS:
            break
        cust_id = order["customer_id"]
        book_id = order["book_id"]
        pair = (cust_id, book_id)
        if pair in used_pairs:
            continue
        used_pairs.add(pair)

        # Rating biased toward book's true quality
        quality = book_quality[book_id]
        raw = random.gauss(quality, 0.8)
        rating = max(1, min(5, round(raw)))

        # Review timestamp: 1–60 days after order_date
        order_date = date.fromisoformat(order["order_date"])
        review_lag = timedelta(days=random.randint(1, 60))
        review_date = order_date + review_lag
        if review_date > END_DATE:
            review_date = END_DATE

        created_at = rand_datetime(review_date)
        review_text = review_text_generator(rating, "")

        # Occasionally null review_text (user just left a star rating)
        if random.random() < 0.08:
            review_text = ""

        rows.append({
            "review_id": review_id,
            "customer_id": cust_id,
            "book_id": book_id,
            "rating": rating,
            "review_text": review_text,
            "created_at": created_at.strftime("%Y-%m-%d %H:%M:%S"),
        })
        review_id += 1

    return rows

# ── 6. Inject Noise ───────────────────────────────────────────────────────────

def inject_noise(orders, customers, books, loans, reviews):
    """
    Injects realistic dirty-data patterns that the Silver layer must catch:
      - Duplicate rows (same PK ingested twice — simulates double-fire ETL)
      - NULL in optional fields (review_text, return_date already handled)
      - Invalid status values (typos, legacy codes)
      - Out-of-range quantities
      - Invalid FK references
      - Invalid ratings (0 or 6)
      - Loan due_date before loan_date
    """
    print("Injecting noise...")

    valid_book_ids  = {b["book_id"] for b in books}
    valid_cust_ids  = {c["customer_id"] for c in customers}
    max_order_id    = orders[-1]["order_id"]
    max_loan_id     = loans[-1]["loan_id"]
    max_review_id   = reviews[-1]["review_id"]

    noisy_orders  = list(orders)
    noisy_loans   = list(loans)
    noisy_reviews = list(reviews)

    # ── Duplicate orders (simulate ETL re-run) ──
    n_dup_orders = int(len(orders) * NOISE_DUPLICATE_RATE)
    dups = random.sample(orders, n_dup_orders)
    for d in dups:
        dup = dict(d)
        max_order_id += 1
        dup["order_id"] = max_order_id   # new PK but same payload
        noisy_orders.append(dup)

    # ── Invalid status values in orders ──
    bad_statuses = ["PROCESSING", "HOLD", "delivered", "Shipped", "RETURN", "FAILED", ""]
    n_bad_status = int(len(orders) * NOISE_INVALID_RATE)
    targets = random.sample(range(len(noisy_orders)), n_bad_status)
    for idx in targets:
        noisy_orders[idx] = dict(noisy_orders[idx])
        noisy_orders[idx]["status"] = random.choice(bad_statuses)

    # ── Out-of-range quantities ──
    n_bad_qty = int(len(orders) * NOISE_INVALID_RATE * 0.5)
    for idx in random.sample(range(len(noisy_orders)), n_bad_qty):
        noisy_orders[idx] = dict(noisy_orders[idx])
        noisy_orders[idx]["quantity"] = random.choice([0, -1, -2, 999, 500])

    # ── Invalid FK: book_id doesn't exist ──
    n_bad_fk = int(len(orders) * 0.006)
    ghost_book_ids = [9999, 8888, 7777, 10000]
    for idx in random.sample(range(len(noisy_orders)), n_bad_fk):
        noisy_orders[idx] = dict(noisy_orders[idx])
        noisy_orders[idx]["book_id"] = random.choice(ghost_book_ids)

    # ── Loan: due_date before loan_date (data entry error) ──
    n_bad_loan_dates = int(len(loans) * 0.008)
    for idx in random.sample(range(len(noisy_loans)), n_bad_loan_dates):
        noisy_loans[idx] = dict(noisy_loans[idx])
        ld = date.fromisoformat(noisy_loans[idx]["loan_date"])
        noisy_loans[idx]["due_date"] = (ld - timedelta(days=random.randint(1, 14))).strftime("%Y-%m-%d")

    # ── Duplicate loans ──
    n_dup_loans = int(len(loans) * NOISE_DUPLICATE_RATE)
    for d in random.sample(loans, n_dup_loans):
        dup = dict(d)
        max_loan_id += 1
        dup["loan_id"] = max_loan_id
        noisy_loans.append(dup)

    # ── Invalid ratings ──
    n_bad_rating = int(len(reviews) * NOISE_INVALID_RATE)
    for idx in random.sample(range(len(noisy_reviews)), n_bad_rating):
        noisy_reviews[idx] = dict(noisy_reviews[idx])
        noisy_reviews[idx]["rating"] = random.choice([0, 6, 7, -1])

    # ── Duplicate reviews ──
    n_dup_reviews = int(len(reviews) * NOISE_DUPLICATE_RATE)
    for d in random.sample(reviews, n_dup_reviews):
        dup = dict(d)
        max_review_id += 1
        dup["review_id"] = max_review_id
        noisy_reviews.append(dup)

    # ── NULL email in customers (some records migrated without email) ──
    noisy_customers = list(customers)
    n_null_email = int(len(customers) * 0.008)
    for idx in random.sample(range(len(noisy_customers)), n_null_email):
        noisy_customers[idx] = dict(noisy_customers[idx])
        noisy_customers[idx]["email"] = ""

    # ── Invalid membership tier ──
    bad_memberships = ["GOLD", "VIP", "basic", "premium", "FREE", ""]
    n_bad_mem = int(len(customers) * 0.007)
    for idx in random.sample(range(len(noisy_customers)), n_bad_mem):
        noisy_customers[idx] = dict(noisy_customers[idx])
        noisy_customers[idx]["membership"] = random.choice(bad_memberships)

    # Shuffle so noise is distributed, not appended to the end
    random.shuffle(noisy_orders)
    random.shuffle(noisy_loans)
    random.shuffle(noisy_reviews)

    return noisy_orders, noisy_customers, noisy_loans, noisy_reviews

# ── 7. Write CSVs ─────────────────────────────────────────────────────────────

def write_csv(filename, rows, fieldnames):
    path = os.path.join(OUT_DIR, filename)
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"  Written: {path}  ({len(rows):,} rows)")

# ── 8. Print summary stats ────────────────────────────────────────────────────

def print_summary(books, customers, orders, loans, reviews):
    print("\n" + "="*60)
    print("DATASET SUMMARY")
    print("="*60)

    genre_counts = defaultdict(int)
    for b in books:
        genre_counts[b["genre"]] += 1
    print(f"\nBooks ({len(books):,} total):")
    for g, c in sorted(genre_counts.items()):
        print(f"  {g:<15} {c:>4} books")

    mem_counts = defaultdict(int)
    for c in customers:
        mem_counts[c["membership"]] += 1
    print(f"\nCustomers ({len(customers):,} total):")
    for m, c in sorted(mem_counts.items()):
        print(f"  {m:<12} {c:>5} customers")

    status_counts = defaultdict(int)
    for o in orders:
        status_counts[o["status"]] += 1
    print(f"\nOrders ({len(orders):,} total, includes noise):")
    for s, c in sorted(status_counts.items()):
        print(f"  {s:<20} {c:>6} orders")

    on_time = sum(1 for l in loans if l["return_date"] and l["return_date"] <= l["due_date"])
    overdue = sum(1 for l in loans if l["return_date"] and l["return_date"] > l["due_date"])
    not_ret = sum(1 for l in loans if not l["return_date"])
    print(f"\nLoans ({len(loans):,} total, includes noise):")
    print(f"  On time:      {on_time:>6,}")
    print(f"  Overdue:      {overdue:>6,}")
    print(f"  Not returned: {not_ret:>6,}")

    rating_dist = defaultdict(int)
    for r in reviews:
        rating_dist[r["rating"]] += 1
    print(f"\nReviews ({len(reviews):,} total, includes noise):")
    for rt in sorted(rating_dist.keys()):
        print(f"  Rating {rt}: {rating_dist[rt]:>6,}")

    print("\n" + "="*60)
    print("Files saved to:", os.path.abspath(OUT_DIR))
    print("="*60 + "\n")

# ── MAIN ──────────────────────────────────────────────────────────────────────

def main():
    print("\n CityReads Dataset Generator")
    print(" Generating realistic, production-like data...\n")

    books     = generate_books()
    customers = generate_customers()
    orders    = generate_orders(books, customers)
    loans     = generate_loans(books, customers)
    reviews   = generate_reviews(books, customers, orders)

    orders, customers, loans, reviews = inject_noise(
        orders, customers, books, loans, reviews
    )

    write_csv("books.csv",     books,     ["book_id","title","author","genre","price","stock","published_on"])
    write_csv("customers.csv", customers, ["customer_id","name","email","city","joined_on","membership"])
    write_csv("orders.csv",    orders,    ["order_id","customer_id","book_id","order_date","quantity","status"])
    write_csv("loans.csv",     loans,     ["loan_id","customer_id","book_id","loan_date","due_date","return_date"])
    write_csv("reviews.csv",   reviews,   ["review_id","customer_id","book_id","rating","review_text","created_at"])

    print_summary(books, customers, orders, loans, reviews)

if __name__ == "__main__":
    main()