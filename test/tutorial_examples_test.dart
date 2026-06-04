import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_tutor/data/tutorial_examples.dart';

void main() {
  test('every curated example produces a hint from its declared technique', () {
    final examples = buildTechniqueExamples();
    expect(examples, isNotEmpty);
    for (final ex in examples) {
      expect(
        ex.hint.techniqueId,
        ex.technique.id,
        reason: 'Example for ${ex.technique.id} produced a different hint',
      );
    }
  });

  test('all four basic + Naked Pair + Hidden Pair examples are present', () {
    final ids = buildTechniqueExamples().map((e) => e.technique.id).toSet();
    expect(ids, containsAll(<String>{
      'naked_single',
      'hidden_single',
      'pointing',
      'box_line',
      'naked_pair',
      'hidden_pair',
    }));
  });
}
