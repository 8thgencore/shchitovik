import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:norms_data/norms_data.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Object and supply parameters; advanced ones are shown in the expert mode.
class ProjectSetupScreen extends StatelessWidget {
  const ProjectSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final state = context.watch<ProjectBloc>().state as ProjectReady;
    final document = state.document;
    final input = document.input;
    final expert = isExpertMode(context);

    void editInput(ProjectInput Function(ProjectInput) change) =>
        ProjectScope.edit(context, (d) => d.copyWith(input: change(d.input)));
    void editSupply(SupplyInput Function(SupplyInput) change) =>
        editInput((i) => i.copyWith(supply: change(i.supply)));
    void editCable(CableDefaults Function(CableDefaults) change) =>
        editInput((i) => i.copyWith(cableDefaults: change(i.cableDefaults)));

    final residential =
        input.objectType == ObjectType.apartment || input.objectType == ObjectType.house;
    return PageBody(
      maxWidth: UiBreakpoints.formMax,
      children: [
        UiFieldGroup(
          title: t.setupGeneral,
          children: [
            CommitTextField(
              value: document.name,
              label: t.setupName,
              validator: context.notBlank,
              onCommitted: (v) => ProjectScope.edit(context, (d) => d.copyWith(name: v.trim())),
            ),
            UiSelect<ObjectType>(
              label: t.objectTypeTitle,
              value: input.objectType,
              options: [for (final type in ObjectType.values) (type, type.label)],
              onChanged: (v) => editInput((i) => i.copyWith(objectType: v)),
            ),
            if (input.objectType == ObjectType.commercial)
              UiSelect<CommercialProfile?>(
                label: t.setupCommercialProfile,
                value: input.commercialProfile,
                options: [
                  (null, t.auto),
                  (CommercialProfile.office, t.profileOffice),
                  (CommercialProfile.shop, t.profileShop),
                  (CommercialProfile.catering, t.profileCatering),
                  (CommercialProfile.services, t.profileServices),
                  (CommercialProfile.workshop, t.profileWorkshop),
                ],
                onChanged: (v) => editInput((i) => i.copyWith(commercialProfile: v)),
              ),
            if (residential && expert)
              UiSelect<CookingFuel?>(
                label: t.setupCookingFuel,
                value: input.cookingFuel,
                options: [
                  (null, t.auto),
                  (CookingFuel.naturalGas, t.cookingFuelNaturalGas),
                  (CookingFuel.liquefiedGasOrSolidFuel, t.cookingFuelLiquefied),
                  (CookingFuel.electric, t.cookingFuelElectric),
                ],
                onChanged: (v) => editInput((i) => i.copyWith(cookingFuel: v)),
              ),
            CommitTextField(
              value: document.note,
              label: t.setupNote,
              onCommitted: (v) => ProjectScope.edit(context, (d) => d.copyWith(note: v)),
            ),
          ],
        ),
        UiFieldGroup(
          title: t.setupSupply,
          children: [
            UiSegmented<SupplyPhases>(
              label: t.supplyTitle,
              segments: [
                UiSegment(value: SupplyPhases.single, label: t.supplySingle),
                UiSegment(value: SupplyPhases.three, label: t.supplyThree),
              ],
              selected: input.supplyPhases,
              onChanged: (v) => editInput((i) => i.copyWith(supplyPhases: v)),
            ),
            DecimalField(
              value: input.supply.allowedPowerKw,
              label: t.setupAllowedPower,
              hint: t.setupAllowedPowerHint,
              onChanged: (v) => editSupply((s) => s.copyWith(allowedPowerKw: v)),
            ),
            DecimalField(
              value: input.supply.externalLoopImpedanceOhm,
              label: t.setupExternalLoop,
              hint: t.setupExternalLoopHint,
              digits: 3,
              onChanged: (v) => editSupply((s) => s.copyWith(externalLoopImpedanceOhm: v)),
            ),
            if (expert) ...[
              DecimalField(
                value: input.supply.incomerBreakerA,
                label: t.setupIncomerBreaker,
                digits: 0,
                onChanged: (v) => editSupply((s) => s.copyWith(incomerBreakerA: v)),
              ),
              UiSelect<String>(
                label: t.setupVoltage,
                value: input.nominalVoltageId,
                options: [
                  for (final v in NormsData.embedded.constants.voltageOptions)
                    (v.id, '${v.phaseV.toStringAsFixed(0)}/${v.lineV.toStringAsFixed(0)} В'),
                ],
                onChanged: (v) => editInput((i) => i.copyWith(nominalVoltageId: v)),
              ),
            ],
          ],
        ),
        UiFieldGroup(
          title: t.setupProtection,
          children: [
            UiSelect<RcdStrategy>(
              label: t.setupRcdStrategy,
              value: input.rcdStrategy,
              options: [
                (RcdStrategy.rcboPerCircuit, t.rcdStrategyRcbo),
                (RcdStrategy.rcdPerCircuit, t.rcdStrategyRcd),
                if (expert || input.rcdStrategy == RcdStrategy.groupedRcd)
                  (RcdStrategy.groupedRcd, t.rcdStrategyGrouped),
              ],
              onChanged: (v) => editInput((i) => i.copyWith(rcdStrategy: v)),
            ),
            UiSelect<bool?>(
              label: t.setupFireRcd,
              value: input.fireRcdAtInput,
              options: [(null, t.auto), (true, t.yes), (false, t.no)],
              onChanged: (v) => editInput((i) => i.copyWith(fireRcdAtInput: v)),
            ),
          ],
        ),
        UiFieldGroup(
          title: t.setupCable,
          children: [
            DecimalField(
              value: input.cableDefaults.lengthM,
              label: t.setupDefaultLength,
              digits: 1,
              onChanged: (v) => editCable((c) => c.copyWith(lengthM: v)),
            ),
            UiSelect<String>(
              label: t.setupMethod,
              value: input.cableDefaults.installationMethodId,
              options: [for (final m in NormsData.embedded.installationMethods) (m.id, m.title)],
              onChanged: (v) => editCable((c) => c.copyWith(installationMethodId: v)),
            ),
            UiSelect<ConductorMaterial>(
              label: t.setupMaterial,
              value: input.cableDefaults.material,
              options: [
                (ConductorMaterial.copper, t.materialCopper),
                (ConductorMaterial.aluminium, t.materialAluminium),
              ],
              onChanged: (v) => editCable((c) => c.copyWith(material: v)),
            ),
            if (expert) ...[
              UiSelect<Insulation>(
                label: t.setupInsulation,
                value: input.cableDefaults.insulation,
                options: [(Insulation.pvc, t.insulationPvc), (Insulation.xlpe, t.insulationXlpe)],
                onChanged: (v) => editCable((c) => c.copyWith(insulation: v)),
              ),
              DecimalField(
                value: input.cableDefaults.ambientTemperatureC,
                label: t.setupAmbient,
                digits: 0,
                validator: (v) => v == null ? t.fieldRequired : null,
                onChanged: (v) => editCable((c) => c.copyWith(ambientTemperatureC: v)),
              ),
              DecimalField(
                value: input.cableDefaults.groupedCircuits.toDouble(),
                label: t.setupGrouped,
                digits: 0,
                validator: context.atLeast(1),
                onChanged: (v) => editCable((c) => c.copyWith(groupedCircuits: v!.round())),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
