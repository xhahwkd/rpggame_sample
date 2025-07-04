import 'dart:io';
import 'dart:math';

class Game {
  Character character;
  List<Monster> monsters = [];
  int monsterCount;

  Game(this.character, this.monsters, this.monsterCount);

  Future<void> startGame() async {
    while (character.health > 0 && monsters.isNotEmpty) {
      Monster monster = getRandomMonster();
      print('\n새로운 몬스터가 나타났습니다!');
      monster.showStatus();

      while (monster.health > 0 && character.health > 0) {
        await Future.delayed(Duration(seconds: 2));
        print('\n${character.name}의 턴');
        character.showStatus();
        monster.showStatus();
        battle(monster);

        if (monster.health <= 0) break;

        await Future.delayed(Duration(seconds: 2));
        print('\n${monster.name}의 턴');
        monster.attackCharacter(character);
      }

      if (character.health <= 0) {
        print('Game Over ☠️');
        saveResult('패배');
        return;
      }

      print('${monster.name}을(를) 물리쳤습니다!');
      monsters.remove(monster);
      monsterCount--;

      if (monsters.isNotEmpty) {
        print('\n다음 몬스터와 싸우시겠습니까? (y/n):');
        String? input = stdin.readLineSync();
        if (input?.toLowerCase() != 'y') {
          saveResult('중단');
          return;
        }
      }
    }

    if (character.health > 0) {
      print('축하합니다. 모든 몬스터를 물리쳤습니다!');
      saveResult('승리');
    }
  } //게임 턴 진행

  saveResult(String result) {
    print('결과를 저장하시겠습니까? (y/n)');
    String? save = stdin.readLineSync();
    if (save == 'y') {
      File('result.txt').writeAsStringSync(
        '${character.name}, ${character.health}, 게임결과: $result',
      );
      print('결과가 저장되었습니다.');
    } else if (save == 'n') {
      print('결과가 저장되지 않았습니다.');
    } else {
      print('잘못된 입력입니다. 다시 입력하세요.');
    }
    exit(0);
  } //게임 결과 저장

  battle(Monster monster) {
    print('행동을 선택하세요 (1: 공격, 2: 방어):');
    String? action = stdin.readLineSync();
    if (action == '1') {
      character.attackMonster(monster);
    } else if (action == '2') {
      character.defend(monster.attack);
    } else {
      print('잘못된 입력입니다. 다시 입력하세요.');
      battle(monster);
    }
  } //몬스터와 대결

  getRandomMonster() {
    Random random = Random(DateTime.now().millisecondsSinceEpoch);
    int index = random.nextInt(monsters.length);
    return monsters[index];
  } //몬스터 랜덤 선택
}

abstract class Creature {
  String name;
  int health;
  int attack;
  int defense;

  Creature(this.name, this.health, this.attack, this.defense);
} //Character와 Monster의 공통 부모 클래스

class Character extends Creature {
  @override
  Character(super.name, super.health, super.attack, super.defense);

  attackMonster(Monster monster) {
    monster.health -= attack;
    print('$name이(가) ${monster.name}에게 $attack의 데미지를 입혔습니다.');
  } //Character의 공격 기능

  defend(int damage) {
    health += damage;
    print('${name}이(가) 방어 태세를 취하여 $damage 만큼 체력을 얻었습니다.');
  } //Character의 방어 기능: 방어 시 데미지만큼 체력 상승

  showStatus() {
    print('${name} - 체력: ${health}, 공격력: ${attack}, 방어력: ${defense}');
  } //Character의 상태 표시 기능
}

class Monster extends Creature {
  @override
  Monster(String name, int health, int maxAttack, int characterDefense)
    : super(name, health, max(maxAttack, characterDefense), 0);

  attackCharacter(Character character) {
    character.health -= attack - character.defense;
    print(
      '${name}이(가) ${character.name}에게 ${attack - character.defense}의 데미지를 입혔습니다.',
    );
  } //Monster의 공격 기능: 공격력이 캐릭터의 방어력보다 높을 경우 캐릭터에게 데미지 입힘

  showStatus() {
    print('${name} - 체력: ${health}, 공격력: ${attack}, 방어력: ${defense}');
  }
} //Monster의 공격, 상태 표시 기능 클래스

Future<Character> loadCharacterStats(String name) async {
  try {
    final file = File('characters.txt');
    final contents = await file.readAsString();
    final stats = contents.split(',');
    if (stats.length != 3) throw FormatException('Invalid character data');

    int health = int.parse(stats[0]);
    int attack = int.parse(stats[1]);
    int defense = int.parse(stats[2]);

    return Character(name, health, attack, defense);
  } catch (e) {
    print('캐릭터 데이터를 불러오는 데 실패했습니다: $e');
    exit(1);
  }
} //비동기 방식으로 캐릭터 데이터 불러오기

Future<List<Monster>> loadMonsterStats(int characterDefense) async {
  try {
    final file = File('monsters.txt');
    final contents = await file.readAsString();
    final lines = contents.trim().split('\n');

    List<Monster> monsters = [];

    for (String line in lines) {
      final stats = line.split(',');
      if (stats.length != 3) continue;

      String name = (stats[0]);
      int health = int.parse(stats[1]);
      int attack = int.parse(stats[2]);

      monsters.add(Monster(name, health, attack, characterDefense));
    }
    return monsters;
  } catch (e) {
    print('몬스터 데이터를 불러오는 데 실패했습니다: $e');
    throw Exception('몬스터 로딩 실패');
  }
} //비동기 방식으로 몬스터 데이터 불러오기

getCharacterName() {
  print('캐릭터의 이름을 입력하세요:');
  String? name = stdin.readLineSync();
  if (name == null || !name.contains(RegExp(r'^[a-zA-Z가-힣]+$'))) {
    print('올바른 이름을 입력하세요.');
    return getCharacterName();
  }
  return name;
} //캐릭터 이름 입력

Future<void> main() async {
  String name = getCharacterName();
  Character character = await loadCharacterStats(name);
  List<Monster> monsters = await loadMonsterStats(character.defense);
  Game game = Game(character, monsters, 1);
  print('게임을 시작합니다!');
  game.startGame();
}
