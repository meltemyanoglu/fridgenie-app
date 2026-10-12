// Dietary rule shared with the app (Recipe.satisfiesDiet in lib/data/models/recipe.dart).

/** Restrictions a recipe also meets when it declares the key restriction. */
const IMPLIED_BY = Object.freeze({
  vegan: ["vegetarian", "dairyFree", "pescatarian"],
  vegetarian: ["pescatarian"],
});

/** True when a recipe tagged with `recipeDietary` meets every entry of `required`. */
export function satisfiesDiet(recipeDietary, required) {
  const fits = new Set(recipeDietary);
  for (const declared of recipeDietary) {
    for (const implied of IMPLIED_BY[declared] ?? []) fits.add(implied);
  }
  return required.every((rule) => rule === "noRestrictions" || fits.has(rule));
}
