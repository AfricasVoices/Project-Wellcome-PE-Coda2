/// Library for generating names of anonymous users
library coda.user;

import 'dart:html';
import 'dart:math';

DivElement userPicElement = querySelector('#user-pic');
DivElement userNameElement = querySelector('#user-name');

String _color;
String _name;
String _email;

/// Initialise user with random details.
init() {
  // Generate this user's details
  String adjective = generateAdjective();
  String animal = generateAnimalName();
  _name = '${adjective} ${animal}';
  _email = '${adjective}.${animal}';

  // Setup the UI details
  userNameElement.text = _name;
}

/// Returns the user's profile pic color.
String getProfilePicColor() {
  return _color;
}

/// Returns the signed-in user's display name.
String getUserName() {
  return _name;
}

/// Returns the signed-in user's email address.
String getUserEmail() {
  return _email;
}

Random _random = new Random();

List<String> _animals = ['Alpaca', 'Armadillo', 'Badger', 'Bat', 'Bear', 'Beaver', 'Chameleon', 'Camel', 'Cat', 'Cheetah', 'Crocodile', 'Dolphin', 'Elephant', 'Fox', 'Frog', 'Giraffe', 'Hedgehog', 'Hippo', 'Iguana', 'Jackal', 'Kangaroo', 'Koala', 'Lemur', 'Leopard', 'Lion', 'Llama', 'Monkey', 'Mouse', 'Otter', 'Panda', 'Penguin', 'Python', 'Rabbit', 'Rhino', 'Seal', 'Squirrel', 'Tiger', 'Turtle', 'Walrus', 'Wolf', 'Wolf', 'Wombat', 'Zebra'];

List<String> _adjectives = [
  'Adventurous', 'Aloof', 'Ambiguous', 'Amused',
  'Benevolent', 'Bewildered', 'Blushing', 'Bouncy',
  'Capricious', 'Cautious', 'Charming', 'Contemplative',
  'Dapper', 'Defiant', 'Dilligent',
  'Eager', 'Egregious', 'Energetic', 'Enthusiastic', 'Exuberant',
  'Familiar', 'Fancy', 'Fastidious', 'Fluffy', 'Friendly',
  'Generous', 'Gentle', 'Giddy', 'Goofy', 'Groovy',
  'Helpful', 'Insightful', 'Invincible',
  'Jocular', 'Jolly', 'Jumpy',
  'Lively', 'Lovely', 'Lyrical',
  'Keen', 'Kind', 'Knowing',
  'Magical', 'Majestic', 'Mannered', 'Mighty', 'Mysterious',
  'Nebulous', 'Nimble', 'Nippy', 'Nifty',
  'Observant', 'Omniscient', 'Outrageous',
  'Petite', 'Prickly', 'Productive', 'Puzzled',
  'Questionable', 'Quixotic', 'Quizzical',
  'Rambunctious', 'Rare', 'Remarkable', 'Romantic',
  'Secretive', 'Serious', 'Shy', 'Sparkling', 'Spicy', 'Splendid', 'Swanky',
  'Talented', 'Teeny', 'Tenacious', 'Thoughtful', 'Tranquil',
  'Unusual', 'Upbeat',
  'Vague', 'Vivacious', 'Voluble', 'Voracious',
  'Wandering', 'Whimsical'];

String generateAdjective() {
  return _adjectives[_random.nextInt(_adjectives.length)];
}

String generateAnimalName() {
  return _animals[_random.nextInt(_animals.length)];
}
