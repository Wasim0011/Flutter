import 'question.dart';
import 'dart:math';

class QuizBrain{
  int _questionNumber=(Random().nextInt(100))+1;
  final List<Question> _questionBank = [ //with '_' questionBank became private
    Question('*****The Quiz in ENDED*****\n\n\nPress any Button to check Your SCORE', true),
    Question('Some cats are actually allergic to humans', true),
    Question('You can lead a cow down stairs but not up stairs.', false),
    Question('Approximately one quarter of human bones are in the feet.', true),
    Question('A slug\'s blood is green.', true),
    Question('Buzz Aldrin\'s mother\'s maiden name was "Moon".', true),
    Question(
        'NIT Raipur came under top 50 Engineering Colleges in India.',
        false),
    Question('It is illegal to pee in the Ocean in Portugal.', true),
    Question(
        'No piece of square dry paper can be folded in half more than 7 times.',
        false),
    Question(
        'In London, UK, if you happen to die in the House of Parliament, you are technically entitled to a state funeral, because the building is considered too sacred a place.',
        true),
    Question(
        'The loudest sound produced by any animal is 188 decibels. That animal is the African Elephant.',
        false),
    Question(
        'The total surface area of two human lungs is approximately 70 square metres.',
        true),
    Question('Google was originally called "Back rub".', true),
    Question(
        'Chocolate affects a dog\'s heart and nervous system; a few ounces are enough to kill a small dog.',
        true),
    Question(
        'Python is faster than C language.',
        false),
    Question(
        'In West Virginia, USA, if you accidentally hit an animal with your car, you are free to take it home to eat.',
        true),
    Question('The capital of France is Paris.', true),
    Question('Water boils at 100 degrees Celsius at standard atmospheric pressure.', true),
    Question('The Earth is the third planet from the Sun.', true),
    Question('There are 24 hours in a day.', true),
    Question('Humans have 206 bones in their adult bodies.', true),
    Question('Venus is the hottest planet in our solar system.', true),
    Question('Goldfish have a three-second memory span.', false),
    Question('The Great Wall of China is visible from space.', false),
    Question('Mount Everest is the highest mountain in the world.', true),
    Question('An octopus has three hearts.', true),
    Question('The human body has five senses.', false),
    Question('Bats are mammals.', true),
    Question('Sharks are mammals.', false),
    Question('The Pacific Ocean is the largest ocean on Earth.', true),
    Question('Lightning never strikes the same place twice.', false),
    Question('Honey never spoils.', true),
    Question('The moon is made of cheese.', false),
    Question('Cats can make over 100 different sounds.', true),
    Question('The human nose can distinguish over 1 trillion different smells.', true),
    Question('A leap year occurs every 4 years.', true),
    Question('The Sun is a planet.', false),
    Question('Jupiter is the largest planet in our solar system.', true),
    Question('Elephants are the only animals that cannot jump.', true),
    Question('There are 12 months in a year.', true),
    Question('The Sahara Desert is the largest desert in the world.', true),
    Question('A group of crows is called a murder.', true),
    Question('The tallest statue in the world is the Statue of Liberty.', false),
    Question('The Pacific Ocean is deeper than the Atlantic Ocean.', true),
    Question('There are 50 states in the United States.', true),
    Question('The Amazon River is the longest river in the world.', false),
    Question('The heart is located in the center of the chest.', false),
    Question('The Eiffel Tower was completed in 1889.', true),
    Question('The chemical symbol for gold is Au.', true),
    Question('The kangaroo is native to Africa.', false),
    Question('The chemical symbol for sodium is Na.', true),
    Question('The Great Pyramid of Giza is one of the Seven Wonders of the Ancient World.', true),
    Question('The human body has four lungs.', false),
    Question('A day on Venus is longer than a year on Venus.', true),
    Question('Penguins are found in the Arctic.', false),
    Question('The longest river in Africa is the Nile.', true),
    Question('The average adult human body is about 70% water.', true),
    Question('There are seven continents on Earth.', true),
    Question('The chemical symbol for silver is Ag.', true),
    Question('The tallest mountain in the solar system is Olympus Mons.', true),
    Question('The Statue of Liberty was a gift from the United Kingdom.', false),
    Question('The color of a flamingo is pink due to its diet.', true),
    Question('A giraffe’s neck has the same number of vertebrae as a human neck.', true),
    Question('The shortest war in history lasted 38 minutes.', true),
    Question('Mammals lay eggs.', false),
    Question('Bees can sting multiple times.', false),
    Question('The Great Barrier Reef is located in Australia.', true),
    Question('The Moon is Earth\'s only natural satellite.', true),
    Question('The word "robot" comes from Czech.', true),
    Question('The world\'s largest desert is Antarctica.', true),
    Question('A snail can sleep for three years.', true),
    Question('Rats can swim.', true),
    Question('An ostrich’s eye is bigger than its brain.', true),
    Question('The most common element in the Earth’s crust is iron.', false),
    Question('Sharks have been around longer than dinosaurs.', true),
    Question('Bananas grow on trees.', false),
    Question('There are more stars in the universe than grains of sand on Earth.', true),
    Question('The shortest day of the year is called the summer solstice.', false),
    Question('Chameleons change color to blend in with their environment.', true),
    Question('Koalas are marsupials.', true),
    Question('The Eiffel Tower can be seen from anywhere in Paris.', false),
    Question('The average person walks about 100,000 miles in their lifetime.', true),
    Question('Crocodiles cannot stick their tongue out.', true),
    Question('A blue whale\'s heart is the size of a small car.', true),
    Question('All polar bears are left-handed.', false),
    Question('The currency of Japan is the yen.', true),
    Question('The fastest animal on land is the cheetah.', true),
    Question('An apple a day keeps the doctor away.', false),
    Question('Octopuses have eight brains.', false),
    Question('The tongue is the strongest muscle in the human body.', false),
    Question('There are 60 seconds in a minute.', true),
    Question('The currency of South Korea is the won.', true),
    Question('The Louvre Museum is located in Rome.', false),
    Question('A butterfly has four wings.', false),
    Question('The smallest bone in the human body is in the ear.', true),
    Question('A group of lions is called a pride.', true),
    Question('The human body has 32 teeth in total.', true),
    Question('A compass points north.', true),
    Question('The largest animal in the world is the elephant.', false),
    Question('The Grand Canyon is located in Arizona.', true),
    Question('The currency of Australia is the Australian dollar.', true),
    Question('There are 100 centimeters in a meter.', true),
    Question('The Great Wall of China was built to keep out tigers.', false),
    Question('The hottest planet in the solar system is Mercury.', false),
    Question('The Titanic sank on its maiden voyage.', true),
    Question('The Eiffel Tower was originally intended to be a temporary structure.', true),
    Question('A dolphin is a type of fish.', false),
    Question('Horses sleep standing up.', true),
    Question('Venus is the closest planet to the Sun.', false),
    Question('The Pacific Ocean is shrinking.', true),
    Question('A penguin’s wings are used for flying.', false),
    Question('The longest mountain range in the world is the Andes.', true),
    Question('The capital of Australia is Sydney.', false),
    Question('The Great Wall of China is more than 13,000 miles long.', true),
    Question('Dolphins are mammals.', true),
    Question('Bamboo is a type of grass.', true),
    Question('The currency of Brazil is the real.', true),
    Question('The smallest country in the world is Monaco.', false),
    Question('The moon orbits the Earth.', true),
    Question('The Sun is a star.', true),
    Question('Humans can breathe underwater.', false),
    Question('The capital of Canada is Toronto.', false),
    Question('Elephants are the largest land animals.', true),
    Question('The chemical symbol for potassium is K.', true),
    Question('Mount Kilimanjaro is located in Africa.', true),
    Question('Australia is both a country and a continent.', true),
    Question('A rainbow has seven colors.', true),
    Question('The Mona Lisa is housed in the Louvre.', true),
    Question('Hummingbirds are the smallest birds.', true),
    Question('Bats are blind.', false),
    Question('Jellyfish have a brain.', false),
    Question('There are 360 degrees in a circle.', true),
    Question('The longest river in the world is the Amazon.', false),
    Question('The smallest unit of life is the cell.', true),
    Question('The currency of Mexico is the peso.', true),
    Question('The largest island in the world is Greenland.', true),
    Question('The capital of Italy is Rome.', true),
    Question('A spider is an insect.', false),
    Question('The Grand Canyon was formed by erosion.', true),
    Question('The human body has five senses.', false),
    Question('Humans share 99% of their DNA with chimpanzees.', true),
    Question('The capital of Germany is Berlin.', true),
    Question('Penguins can fly.', false),
    Question('A bee’s lifespan is about one year.', false),
    Question('The longest recorded flight of a chicken is 13 seconds.', true),
    Question('A group of dolphins is called a pod.', true),
    Question('The capital of Spain is Madrid.', true),
    Question('A giraffe’s tongue is blue.', true),
    Question('The shortest month of the year is February.', true),
    Question('Lions are the only cats that live in groups.', true),
    Question('Butterflies can live for up to a year.', false),
    Question('The color orange is named after the fruit.', true),
    Question('The capital of Egypt is Cairo.', true),
    Question('A group of owls is called a parliament.', true),
    Question('The Great Wall of China is longer than the circumference of the Earth.', false),
  ];

  int count=0;
  int totalQuestion=10;
  int score=0;
  void nextQuestion(){
    if(count<totalQuestion){
      _questionNumber=(Random().nextInt(_questionBank.length-2))+1; //1 to total question
      count++;
      if(count==totalQuestion){
        _questionNumber=0;
      }
    }
    // else{
    //   _questionNumber=0;
    //   count++;
    // }
  }

  bool isFinished(){
    if(count>=totalQuestion){
      return true;
    }
    else{
      return false;
    }
  }

  String getQuestionText(){
    return _questionBank[_questionNumber].questionText;
  }
  bool getCorrectAnswer(){
    return _questionBank[_questionNumber].questionAnswer;
  }



  void reset(){
    count=0;
    _questionNumber=Random().nextInt(_questionBank.length-1);
    score=0;
  }
}

