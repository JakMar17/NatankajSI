from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.orm import MolStation, MolStationCard, MolStationGastro, MolStationService
from app.models.schemas import (
    MolCardSchema,
    MolDataSchema,
    MolGastroCategorySchema,
    MolServiceSchema,
)


def mol_to_schema(mol: MolStation) -> MolDataSchema:
    loc = " ".join(filter(None, [mol.postcode, mol.city]))
    parts = [p for p in [mol.street_address, loc or None] if p]
    return MolDataSchema(
        mol_code=mol.mol_code,
        company=mol.company,
        brand=mol.brand,
        name=mol.name,
        address=", ".join(parts) or None,
        city=mol.city,
        postcode=mol.postcode,
        lat=mol.lat,
        lng=mol.lng,
        status=mol.status,
        shop_size=mol.shop_size,
        num_of_pos=mol.num_of_pos,
        services=[
            MolServiceSchema(code=ss.service_type.code, name=ss.service_type.name, value=ss.value)
            for ss in mol.services
        ],
        cards=[MolCardSchema(code=sc.card_type.code, name=sc.card_type.name) for sc in mol.cards],
        gastro=[
            MolGastroCategorySchema(code=sg.gastro_category.code, name=sg.gastro_category.name)
            for sg in mol.gastro
        ],
    )


async def load_mol_map(session: AsyncSession, station_pks: list[int]) -> dict[int, MolDataSchema]:
    if not station_pks:
        return {}
    result = await session.execute(
        select(MolStation)
        .options(
            selectinload(MolStation.services).selectinload(MolStationService.service_type),
            selectinload(MolStation.cards).selectinload(MolStationCard.card_type),
            selectinload(MolStation.gastro).selectinload(MolStationGastro.gastro_category),
        )
        .where(MolStation.station_id.in_(station_pks))
    )
    return {ms.station_id: mol_to_schema(ms) for ms in result.scalars().all()}
