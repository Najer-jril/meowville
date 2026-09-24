import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/relative_date.dart';
import '../entities/room_catalog.dart';
import '../entities/room_drafts.dart';
import '../entities/room_type.dart';
import '../entities/room_unit.dart';
import '../repositories/admin_room_repository.dart';

class LoadRoomCatalogUseCase {
  const LoadRoomCatalogUseCase(this._repository, this._clock);

  final AdminRoomRepository _repository;
  final Clock _clock;

  Future<RoomCatalog> call() =>
      _repository.loadCatalog(today: dateOnly(_clock()));
}

class SaveRoomUseCase {
  const SaveRoomUseCase(this._repository, this._clock);

  final AdminRoomRepository _repository;
  final Clock _clock;

  Future<int> call({int? roomId, required RoomDraft draft}) async {
    final Map<RoomField, String> errors = draft.validate();
    if (errors.isNotEmpty) {
      throw ValidationException(errors.values.first);
    }
    final RoomType type = draft.type!;
    final String description = draft.description.trim();
    final RoomFields fields = RoomFields(
      type: type,
      description: description.isEmpty ? null : description,
      includedServices: draft.includedServices.trim(),
      pricePerNight: draft.price!,
    );

    if (roomId == null) {
      final int createdId = await _repository.createRoom(fields);
      await _repository.applyUnitPlan(
        createdId,
        UnitPlan.toReach(
          target: draft.unitCount,
          type: type,
          units: const <RoomUnit>[],
        ),
      );
      return createdId;
    }

    // Data unit ditarik ulang di sini, bukan dari layar, agar batas bawah
    // memakai reservasi terbaru. Rencana dihitung sebelum menulis apa pun.
    final RoomUnitsState state = await _repository.loadUnits(
      roomId,
      today: dateOnly(_clock()),
    );
    if (draft.unitCount < state.activeReservations) {
      throw ValidationException(
        'Tidak bisa kurang dari ${state.activeReservations}, '
        'jumlah reservasi aktif.',
      );
    }
    final UnitPlan plan = UnitPlan.toReach(
      target: draft.unitCount,
      type: type,
      units: state.units,
      bookedUnitIds: state.bookedUnitIds,
    );
    await _repository.updateRoom(roomId, fields);
    if (!plan.isEmpty) {
      await _repository.applyUnitPlan(roomId, plan);
    }
    return roomId;
  }
}

class DeleteRoomUseCase {
  const DeleteRoomUseCase(this._repository);

  final AdminRoomRepository _repository;

  Future<void> call(int roomId) => _repository.deleteRoom(roomId);
}

class CreateRoomBlockUseCase {
  const CreateRoomBlockUseCase(this._repository);

  final AdminRoomRepository _repository;

  Future<void> call({
    required RoomBlockDraft draft,
    required String? adminId,
  }) async {
    if (adminId == null || adminId.isEmpty) {
      throw const UnauthorizedException(
        'Sesi admin tidak ditemukan. Masuk ulang, lalu coba lagi.',
      );
    }
    final Map<BlockField, String> errors = draft.validate();
    if (errors.isNotEmpty) {
      throw ValidationException(errors.values.first);
    }
    final String purpose = draft.purpose.trim();
    await _repository.createBlock(
      NewRoomBlock(
        roomId: draft.roomId!,
        dateStart: draft.dateStart!,
        dateEnd: draft.dateEnd!,
        blockedUnits: draft.blockedUnits,
        purpose: purpose.isEmpty ? null : purpose,
        createdBy: adminId,
      ),
    );
  }
}

class DeleteRoomBlockUseCase {
  const DeleteRoomBlockUseCase(this._repository);

  final AdminRoomRepository _repository;

  Future<void> call(String blockId) => _repository.deleteBlock(blockId);
}
