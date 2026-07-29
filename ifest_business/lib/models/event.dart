class Event {
  final String id;
  final String title;
  final String organizer;
  final String date;
  final String location;
  final double price;
  final String imageUrl;
  final String description;

  const Event({
    required this.id,
    required this.title,
    required this.organizer,
    required this.date,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.description,
  });
}

// Mock Data matching the UI mockup reference
const List<Event> mockEvents = [
  Event(
    id: '1',
    title: 'Prambanan Jazz Festival 2026',
    organizer: 'Rajawali Indonesia',
    date: 'Jun 15, 2026',
    location: 'Yogyakarta',
    price: 20.0,
    imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=60',
    description: '"Sewindu Celebrating Rindu" was appointed as the main theme of the event. Various musicians both from Indonesia and internationally are ready to waken your romantic soul.',
  ),
  Event(
    id: '2',
    title: 'Synchronize Fest 2026',
    organizer: 'Synchronize',
    date: 'Mar 15, 2026',
    location: 'Jakarta',
    price: 25.0,
    imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=60',
    description: 'A multi-genre annual music festival in Jakarta, Indonesia, presenting local acts from past eras to current trends.',
  ),
  Event(
    id: '3',
    title: 'Jakarta Town Festival',
    organizer: 'Kopi Pangku',
    date: 'Aug 10, 2026',
    location: 'Jakarta',
    price: 20.0,
    imageUrl: 'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=500&auto=format&fit=crop&q=60',
    description: 'A grand celebration of community and modern urban music in the heart of Jakarta.',
  ),
  Event(
    id: '4',
    title: 'Didi Kempot Sang Maestro',
    organizer: 'Sobat Ambyar',
    date: 'Sep 22, 2026',
    location: 'Nganjuk',
    price: 34.0,
    imageUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=500&auto=format&fit=crop&q=60',
    description: 'A tribute concert dedicated to the legendary Indonesian campursari singer.',
  ),
];
