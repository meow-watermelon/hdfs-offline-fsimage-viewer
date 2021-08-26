#!/usr/bin/env tclsh

package require Tk
package require tablelist
package require tdom

wm title . "HDFS Offline FSImage Viewer"
wm geometry . "1200x600"
wm minsize . 900 600

################
# GLOBAL PROCS #
################

# entry insert proc
proc entry_insert {entry_name value} {
	$entry_name configure -state normal
	$entry_name delete 0 end
	$entry_name insert end $value
	$entry_name configure -state readonly -readonlybackground white
}

# load fsimage XML file and return the DOM object
proc get_xml_dom {fsimage_xml_file} {
    set fsimage_xml_fd [open $fsimage_xml_file r]

    # due to the default Tcl string size limit(2GB), needs to use -channel option to read directly
    set fsimage_dom [dom parse -channel $fsimage_xml_fd]
    close $fsimage_xml_fd
    set root [$fsimage_dom documentElement]

    return $root
}

# get fsimage XML file path from getOpenFile
proc get_fsimage_xml_file_path {} {
    global env
    set fsimage_xml_file_path [tk_getOpenFile -title "Open a fsimage XML file" -initialdir $env(HOME)]

    return $fsimage_xml_file_path
}
####################
# GLOBAL PROCS END #
####################

# get version section
proc get_fsimage_version {fsimage_dom_root} {
    # get version item values
    set layout_version [[lindex [$fsimage_dom_root selectNodes /fsimage/version/layoutVersion/text()] 0] nodeValue]
    set ondisk_version [[lindex [$fsimage_dom_root selectNodes /fsimage/version/onDiskVersion/text()] 0] nodeValue]
    set oiv_revision [[lindex [$fsimage_dom_root selectNodes /fsimage/version/oivRevision/text()] 0] nodeValue]

    # set version dict
    set fsimage_version [dict create "Layout Version" $layout_version "OnDisk Version" $ondisk_version "OIV Revision" $oiv_revision]

    return $fsimage_version
}

# load fsimage version section UI
proc load_fsimage_version_ui {fsimage_version_dict} {
    # destroy version section label frame if exists already
    if {[winfo exists .fsimage_info.version] == 1} {
        destroy .fsimage_info.version
    }

    # construct labelframe
    labelframe .fsimage_info.version -text "Version Section" -labelanchor n
    grid .fsimage_info.version -row 0 -column 0 -sticky nsew

    # fill out data with labels and entries
    set row 0

    dict for {key value} $fsimage_version_dict {
        label .fsimage_info.version.l$key -text $key -justify left
        entry .fsimage_info.version.e$key -width 48 -justify right

        # insert value
        entry_insert .fsimage_info.version.e$key $value

        grid .fsimage_info.version.l$key -row $row -column 0 -sticky w -padx 5
        grid .fsimage_info.version.e$key -row $row -column 1 -sticky e -padx 5

        incr row 1
    }
}

# get name section
proc get_fsimage_name {fsimage_dom_root} {
    # get name item values
    set namespace_id [[lindex [$fsimage_dom_root selectNodes /fsimage/NameSection/namespaceId/text()] 0] nodeValue]
    set genstamp_v1 [[lindex [$fsimage_dom_root selectNodes /fsimage/NameSection/genstampV1/text()] 0] nodeValue]
    set genstamp_v2 [[lindex [$fsimage_dom_root selectNodes /fsimage/NameSection/genstampV2/text()] 0] nodeValue]
    set genstamp_v1_limit [[lindex [$fsimage_dom_root selectNodes /fsimage/NameSection/genstampV1Limit/text()] 0] nodeValue]
    set last_allocated_block_id [[lindex [$fsimage_dom_root selectNodes /fsimage/NameSection/lastAllocatedBlockId/text()] 0] nodeValue]
    set tx_id [[lindex [$fsimage_dom_root selectNodes /fsimage/NameSection/txid/text()] 0] nodeValue]

    # set name dict
    set fsimage_name [dict create "Namespace ID" $namespace_id "GenStamp V1" $genstamp_v1 "GenStamp V2" $genstamp_v2 "GenStamp V1 Limit" $genstamp_v1_limit "Last Allocated Block ID" $last_allocated_block_id "Transaction ID" $tx_id]

    return $fsimage_name
}

# load fsimage name section UI
proc load_fsimage_name_ui {fsimage_name_dict} {
    # destroy name section label frame if exists already
    if {[winfo exists .fsimage_info.name] == 1} {
        destroy .fsimage_info.name
    }

    # construct labelframe
    labelframe .fsimage_info.name -text "Name Section" -labelanchor n
    grid .fsimage_info.name -row 1 -column 0 -sticky nsew

    # fill out data with labels and entries
    set row 0

    dict for {key value} $fsimage_name_dict {
        label .fsimage_info.name.l$key -text $key -justify left
        entry .fsimage_info.name.e$key -width 32 -justify right

        # insert value
        entry_insert .fsimage_info.name.e$key $value

        grid .fsimage_info.name.l$key -row $row -column 0 -sticky w -padx 5
        grid .fsimage_info.name.e$key -row $row -column 1 -sticky e -padx 5

        incr row 1
    }

    grid columnconfigure .fsimage_info.name 1 -weight 1
}

# get inode section - basic inode information only
proc get_fsimage_inode {fsimage_dom_root} {
    # get inode item values
    set last_inode_id [[lindex [$fsimage_dom_root selectNodes /fsimage/INodeSection/lastInodeId/text()] 0] nodeValue]
    set num_inodes [[lindex [$fsimage_dom_root selectNodes /fsimage/INodeSection/numInodes/text()] 0] nodeValue]

    # set inode dict
    set fsimage_inode [dict create "Last INode ID" $last_inode_id "Number of INodes" $num_inodes]

    return $fsimage_inode
}

# load fsimage inode section UI
proc load_fsimage_inode_ui {fsimage_inode_dict} {
    # destroy inode section label frame if exists already
    if {[winfo exists .fsimage_info.inode] == 1} {
        destroy .fsimage_info.inode
    }

    # construct labelframe
    labelframe .fsimage_info.inode -text "INode Section" -labelanchor n
    grid .fsimage_info.inode -row 2 -column 0 -sticky nsew

    # fill out data with labels and entries
    set row 0

    dict for {key value} $fsimage_inode_dict {
        label .fsimage_info.inode.l$key -text $key -justify left
        entry .fsimage_info.inode.e$key -width 16 -justify right

        # insert value
        entry_insert .fsimage_info.inode.e$key $value

        grid .fsimage_info.inode.l$key -row $row -column 0 -sticky w -padx 5
        grid .fsimage_info.inode.e$key -row $row -column 1 -sticky e -padx 5

        incr row 1
    }

    grid columnconfigure .fsimage_info.inode 1 -weight 1
}

# load fsimage inode details section UI
proc load_fsimage_inode_details_ui {fsimage_dom_root} {
    # destroy inode details section label frame if exists already
    if {[winfo exists .inode_detail] == 1} {
        destroy .inode_detail
    }

    # construct labelframe
    labelframe .inode_detail -text "INode Details Section" -labelanchor n
    grid .inode_detail -row 0 -column 1 -sticky nsew


    # set up tablelist
    tablelist::tablelist .inode_detail.tablelist -columns {0 "ID" 0 "Name" 0 "Type" 0 "Modification Time" 0 "Access Time" 0 "Permission" 0 "Name Quota" 0 "Space Quota" 0 "Replication" 0 "Preferred Block Size" 0 "Storage Policy ID"} -showseparators yes -selectbackground cyan -stripebackground #f0f0f0 -movablecolumns yes -xscrollcommand [list .inode_detail.horizontal_sb set] -yscrollcommand [list .inode_detail.vertical_sb set]

    scrollbar .inode_detail.horizontal_sb -orient horizontal -command [list .inode_detail.tablelist xview]
    scrollbar .inode_detail.vertical_sb -orient vertical -command [list .inode_detail.tablelist yview]

    grid .inode_detail.tablelist -row 0 -column 0 -sticky nsew
    grid .inode_detail.horizontal_sb -row 1 -column 0 -sticky nsew
    grid .inode_detail.vertical_sb -row 0 -column 1 -sticky nsew
    grid rowconfigure .inode_detail 0 -weight 1
    grid columnconfigure .inode_detail 0 -weight 1

    # set a list for inode elements - order matters
    set inode_elements {id name type mtime atime permission nsquota dsquota replication preferredBlockSize storagePolicyId}

    # skip first 2 general information nodes
    set inodes_dom [lrange [[$fsimage_dom_root selectNodes /fsimage/INodeSection] childNodes] 2 end]

    # fill out inode details
    foreach inode_dom $inodes_dom {
        set inode {}

        foreach inode_element $inode_elements {
            if {[catch {set inode_$inode_element [[$inode_dom selectNodes ./$inode_element/text()] nodeValue]}] == 1} {
                set inode_$inode_element ""
            }

            lappend inode [set inode_$inode_element]
        }

        #puts $inode
        lappend inodes $inode

        # insert data into the tablelist
        .inode_detail.tablelist insert end $inode
    }
}

# load fsimage XML into UI - main proc to load everything
proc load_fsimage_ui {} {
    set fsimage_xml_file_path [get_fsimage_xml_file_path]

    if {[info exists fsimage_xml_file_path] == 1 && $fsimage_xml_file_path != ""} {
        set fsimage_dom_root [get_xml_dom $fsimage_xml_file_path]

        # set up general info labelframe
        if {[winfo exists .fsimage_info] == 1} {
            destroy .fsimage_info
        }

        labelframe .fsimage_info -text "FSImage General Information" -labelanchor n
        grid .fsimage_info -row 0 -column 0 -sticky nsew

        # version section UI
        set fsimage_version_dict [get_fsimage_version $fsimage_dom_root]
        load_fsimage_version_ui $fsimage_version_dict

        # name section UI
        set fsimage_name_dict [get_fsimage_name $fsimage_dom_root]
        load_fsimage_name_ui $fsimage_name_dict

        # inode section UI
        set fsimage_inode_dict [get_fsimage_inode $fsimage_dom_root]
        load_fsimage_inode_ui $fsimage_inode_dict

        # inode details section UI
        load_fsimage_inode_details_ui $fsimage_dom_root

        # clear DOM doc - free memory
        $fsimage_dom_root delete
    }

    # expand the INode Details widget
    grid rowconfigure . 0 -weight 1
    grid columnconfigure . 1 -weight 1
}

# main UI
menu .mbar
. configure -menu .mbar

.mbar add cascade -label File -menu .mbar.file -underline 0
menu .mbar.file -tearoff 0
.mbar.file add command -label "Open XML File" -command {load_fsimage_ui}
.mbar.file add separator
.mbar.file add command -label "Exit" -command {exit}
