// The dietary rule must match Recipe.satisfiesDiet in the Flutter app.

import { describe, expect, it } from "vitest";
import { satisfiesDiet } from "../src/diet.js";

describe("satisfiesDiet", () => {
  it("requires every restriction", () => {
    expect(satisfiesDiet(["vegetarian"], ["vegetarian", "glutenFree"])).toBe(false);
    expect(satisfiesDiet(["vegetarian", "glutenFree"], ["vegetarian", "glutenFree"])).toBe(true);
  });

  it("applies implications from vegan and vegetarian", () => {
    expect(satisfiesDiet(["vegan"], ["vegetarian", "dairyFree", "pescatarian"])).toBe(true);
    expect(satisfiesDiet(["vegetarian"], ["pescatarian"])).toBe(true);
    expect(satisfiesDiet(["vegetarian"], ["vegan"])).toBe(false);
    expect(satisfiesDiet(["pescatarian"], ["vegetarian"])).toBe(false);
  });

  it("ignores noRestrictions and accepts anything when nothing is required", () => {
    expect(satisfiesDiet([], ["noRestrictions"])).toBe(true);
    expect(satisfiesDiet([], [])).toBe(true);
  });
});
