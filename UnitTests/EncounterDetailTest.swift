//
//  EncounterDetailTest.swift
//  UnitTests
//
//  Created by Thomas Visser on 18/06/2020.
//  Copyright © 2020 Thomas Visser. All rights reserved.
//

import Foundation
import ComposableArchitecture
import XCTest
@testable import Construct

class EncounterDetailTest: XCTestCase {

    func testFlow_RemoveActiveCombatant() {
        let initialState = EncounterDetailViewState(building: Encounter(name: "", combatants: [
            Combatant(adHoc: AdHocCombatantDefinition(
                        id: UUID(),
                        stats: apply(StatBlock.default) {
                            $0.initiative = Initiative(modifier: .init(modifier: 1), advantage: false)
                        })),
            Combatant(adHoc: AdHocCombatantDefinition(
                        id: UUID(),
                        stats: apply(StatBlock.default) {
                            $0.initiative = Initiative(modifier: .init(modifier: 1), advantage: false)
                        })),
        ]))

        let store = TestStore(
            initialState: initialState,
            reducer: EncounterDetailViewState.reducer,
            environment: Environment(window: UIWindow(), generateUUID: UUID.fakeGenerator(), rng: EverIncreasingRandomNumberGenerator())
        )

        store.assert(
            // start encounter
            .send(.onRunEncounterTap),
            .receive(.run(nil)) {
                var encounter = $0.building
                encounter.ensureStableDiscriminators = true
                $0.running = RunningEncounter(id: UUID(fakeSeq: 0), base: encounter, current: encounter)
            },
            // roll initiative
            .send(.runningEncounter(.current(.initiative(InitiativeSettings.default)))) {
                $0.running!.current.combatants[0].initiative = 2
                $0.running!.current.combatants[1].initiative = 3
                $0.running!.turn = .init(round: 1, combatantId: $0.running!.current.combatants[1].id)
            },
            // remove second combatant (who has the current turn)
            .send(.runningEncounter(.current(.remove(initialState.building.combatants[1])))) {
                $0.running!.current.combatants.remove(at: 1)
                $0.running!.turn = .init(round: 1, combatantId: $0.running!.current.combatants[0].id)
            }
        )
    }

}
