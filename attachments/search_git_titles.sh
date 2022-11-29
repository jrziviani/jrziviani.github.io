#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "expected remote/branch"
    exit 1
fi

while read line; do
    ret=$(git log --oneline --after='2 years ago' "$1" | grep -F "$line")
    [ -z "$ret" ] && echo "[NOT FOUND] $line" || echo "$ret"
done <<COMMITS
powerpc/powernv/npu: Fault user page into the hypervisor's pagetable
Small fix to trace.h
various fixes
vfio_pci: Add NVIDIA GV100GL [Tesla V100 SXM2] subdriver
vfio_pci: Allow regions to add own capabilities
vfio_pci: Allow mapping extra regions
powerpc/powernv/npu: Check mmio_atsd array bounds when populating
powerpc/powernv/npu: Add release_ownership hook
powerpc/powernv/npu: Add compound IOMMU groups
powerpc/powernv/npu: Convert NPU IOMMU helpers to iommu_table_group_ops
powerpc/powernv/npu: Move single TVE handling to NPU PE
powerpc/powernv: Reference iommu_table while it is linked to a group
powerpc/iommu_api: Move IOMMU groups setup to a single place
powerpc/powernv/pseries: Rework device adding to IOMMU groups
powerpc/pseries: Remove IOMMU API support for non-LPAR systems
powerpc/pseries/npu: Enable platform support
powerpc/pseries/iommu: Use memory@ nodes in max RAM address calculation
powerpc/powernv/npu: Move OPAL calls away from context manipulation
powerpc/powernv: Move npu struct from pnv_phb to pci_controller
powerpc/vfio/iommu/kvm: Do not pin device memory
powerpc/mm/iommu/vfio_spapr_tce: Change mm_iommu_get to reference a region
powerpc/ioda/npu: Call skiboot's hot reset hook when disabling NPU2
powerpc/powernv/npu: Remove unused headers and a macro.
powerpc/powernv/ioda: Allocate indirect TCE levels of cached userspace addresses on demand
powerpc/powernv/ioda: Reduce a number of hooks in pnv_phb
powerpc/powernv/ioda1: Remove dead code for a single device PE
powerpc/powernv/eeh/npu: Fix uninitialized variables in opal_pci_eeh_freeze_status
vfio/spapr_tce: Get rid of possible infinite loop
KVM: PPC: Remove redundand permission bits removal
(skip?) KVM: PPC: Expose userspace mm context id via debugfs
(skip?) VM: PPC: Rename kvmppc_tce_to_ua to kvmppc_gpa_to_ua
(skip?) cxl: Remove unused include
xmom stack protector debug
vfio/pci: Quiet broken INTx whining when INTx is unsupported by device
powerpc/mm/iommu: Allow large IOMMU page size only for hugetlb backing
powerpc/mm/iommu: Allow migration of cma allocated pages during mm_iommu_get
mm: Add get_user_pages_cma_migrate
powerpc/mm/radix: implement LPID based TLB flushes to be used by KVM
powerpc/mm/radix: Fix checkstops caused by invalid tlbiel
powerpc/64s: Improve local TLB flush for boot and MCE on POWER9
powerpc/mm/radix: Move the functions that does the actual tlbie closer
powerpc/mm/radix: Remove unused code
vfio: add edid api for display (vgpu) devices.
vfio/pci: Make IGD support a configurable option
vfio-pci: Allow mapping MSIX BAR
vfio: Simplify capability helper
powerpc/64: Interrupts save PPR on stack rather than thread_struct
powerpc: Use SWITCH_FRAME_SIZE for prom and rtas entry
powerpc: Split user/kernel definitions of struct pt_regs
KVM: PPC: Book3S HV: Avoid crash from THP collapse during radix page fault
KVM: PPC: Book3S HV: Don't use compound_order to determine host mapping size
KVM: PPC: Book3S HV: radix: Do not clear partition PTE when RC or write bits do not match
KVM: PPC: Book3S HV: radix: Refine IO region partition scope attributes
KVM: PPC: Book3S HV: Use __gfn_to_pfn_memslot() in page fault handler
KVM: PPC: Book3S HV: Make radix handle process scoped LPID flush in C, with relocation on
KVM: PPC: Book3S HV: Make radix use the Linux translation flush functions for partition scope
KVM: PPC: Book3S HV: Make radix use correct tlbie sequence in kvmppc_radix_tlbie_page
KVM: PPC: Book3S HV: Recursively unmap all page table entries when unmapping
KVM: PPC: Book3S HV: Use a helper to unmap ptes in the radix fault path
powerpc/kvm: Switch kvm pmd allocator to custom allocator
KVM: PPC: Book3S HV: Handle 1GB pages in radix page fault handler
KVM: PPC: Book3S HV: Streamline setting of reference and change bits
KVM: PPC: Book3S HV: Radix page fault handler optimizations
powerpc/powernv/ioda2: Reduce upper limit for DMA window size (again)
powerpc/iommu: Avoid derefence before pointer check
powerpc/powernv: Make possible for user to force a full ipl cec reboot
crypto/nx: Initialize 842 high and normal RxFIFO control registers
powerpc/powernv: Export opal_check_token symbol
powerpc/powernv: Add support to enable sensor groups
powerpc/powernv: call OPAL_QUIESCE before OPAL_SIGNAL_SYSTEM_RESET
powernv: opal-sensor: Add support to read 64bit sensor values
powerpc/pci: Separate SR-IOV Calls
powerpc/pseries: Add pseries SR-IOV Machine dependent calls
powerpc/powernv/npu: Remove atsd_threshold debugfs setting
powerpc/powernv/npu: Use size-based ATSD invalidates
powerpc/powernv/npu: Reduce eieio usage when issuing ATSD invalidates
powerpc/powernv/npu: Add a debugfs setting to change ATSD threshold
hugetlb, mbind: fall back to default policy if vma is NULL
hugetlb, mempolicy: fix the mbind hugetlb migration
mm, migrate: remove reason argument from new_page_t
KVM: PPC: Book3S: Fix guest DMA when guest partially backed by THP pages
mm, numa: rework do_pages_move
mm/migrate: rename migration reason MR_CMA to MR_CONTIG_RANGE
mm, hugetlb: further simplify hugetlb allocation API
mm, hugetlb: get rid of surplus page accounting tricks
mm, hugetlb: do not rely on overcommit limit during migration
mm, hugetlb: integrate giga hugetlb more naturally to the allocation path
mm, hugetlb: unify core page allocation accounting and initialization
mm: change return type to vm_fault_t
KVM: PPC: Optimize clearing TCEs for sparse tables
KVM: PPC: Book3S HV: Add a debugfs file to dump radix mappings
KVM: PPC: Remove redundand permission bits removal
KVM: PPC: Propagate errors to the guest when failed instead of ignoring
KVM: PPC: Avoid marking DMA-mapped pages dirty in real mode
KVM: PPC: Validate TCEs against preregistered memory page sizes
KVM: PPC: Inform the userspace about TCE update failures
KVM: PPC: Validate all tces before updating tables
powerpc/powernv/ioda: Allocate indirect TCE levels on demand
powerpc/powernv: Rework TCE level allocation
powerpc/powernv: Add indirect levels to it_userspace
KVM: PPC: Make iommu_table::it_userspace big endian
powerpc/powernv: Move TCE manupulation code to its own file
KVM: PPC: Book 3S HV: Do ptesync in radix guest exit path
KVM: PPC: Book3S HV: Make radix clear pte when unmapping
KVM: PPC: Book3S HV: Use correct pagesize in kvm_unmap_radix()
powerpc/powernv: Remove useless wrapper
powerpc/msi: Remove VLA usage
powerpc/powernv/ioda2: Add 256M IOMMU page size to the default POWER8 case
cxl: Remove abandonned capi support for the Mellanox CX4, final cleanup
Revert "cxl: Allow a default context to be associated with an external pci_dev"
Revert "cxl: Add cxl_slot_is_supported API"
Revert "powerpc/powernv: Add support for the cxl kernel api on the real phb"
Revert "cxl: Add support for using the kernel API with a real PHB"
Revert "cxl: Add cxl_check_and_switch_mode() API to switch bi-modal cards"
Revert "cxl: Add kernel APIs to get & set the max irqs per context"
Revert "cxl: Add preliminary workaround for CX4 interrupt limitation"
Revert "cxl: Add support for interrupts on the Mellanox CX4"
Revert "cxl: Add kernel API to allow a context to operate with relocate disabled"
powerpc/powernv/ioda2: Reduce upper limit for DMA window size
powerpc/powernv: Use __raw_[rm_]writeq_be() in npu-dma.c
powerpc/powernv: Use __raw_[rm_]writeq_be() in pci-ioda.c
powerpc/io: Add __raw_writeq_be() __raw_rm_writeq_be()
powerpc/ioda: Use ibm, supported-tce-sizes for IOMMU page size mask
powerpc/powernv/npu: Do not try invalidating 32bit table when 64bit table is enabled
powerpc: Use sizeof(*foo) rather than sizeof(struct foo)
powerpc/powernv/idoa: Remove unnecessary pcidev from pci_dn
kvm: no need to check return value of debugfs_create functions
COMMITS
