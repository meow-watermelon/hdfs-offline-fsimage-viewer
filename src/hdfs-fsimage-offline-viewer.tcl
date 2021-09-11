#!/usr/bin/env tclsh

package require csv
package require log
package require Tk
package require tablelist
package require tdom

wm title . "HDFS Offline FSImage Viewer"
wm geometry . "1200x600"
wm minsize . 900 600

################
# GLOBAL PROCS #
################

# log progress update in terminal
proc log_progress {debug_level log_message} {
    set log_time [clock format [clock seconds]]
    set log_level [string toupper $debug_level]

    puts "$log_time - $log_level - $log_message"
}

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

# get inode details TSV file path from getSaveFile
proc get_inode_tsv_file_path {} {
    global env
    set inode_tsv_file_path [tk_getSaveFile -title "Save an INode TSV file" -initialdir $env(HOME)]

    return $inode_tsv_file_path
}

####################
# GLOBAL PROCS END #
####################

# get version section
proc get_fsimage_version {fsimage_dom_root} {
    # get version item values
    set layout_version [$fsimage_dom_root selectNodes string(/fsimage/version/layoutVersion)]
    set ondisk_version [$fsimage_dom_root selectNodes string(/fsimage/version/onDiskVersion)]
    set oiv_revision [$fsimage_dom_root selectNodes string(/fsimage/version/oivRevision)]

    # set version dict
    set fsimage_version [dict create "Layout Version" $layout_version "OnDisk Version" $ondisk_version "OIV Revision" $oiv_revision]

    return $fsimage_version
}

# load fsimage version section UI
proc load_fsimage_version_ui {fsimage_version_dict} {
    # destroy version section label frame if exists already
    if {[winfo exists .pw.fsimage_info.version] == 1} {
        destroy .pw.fsimage_info.version
    }

    # construct labelframe
    labelframe .pw.fsimage_info.version -text "Version Section" -labelanchor n
    grid .pw.fsimage_info.version -row 0 -column 0 -sticky ew

    # fill out data with labels and entries
    set row 0

    dict for {key value} $fsimage_version_dict {
        label .pw.fsimage_info.version.l$key -text $key -justify left
        entry .pw.fsimage_info.version.e$key -width 48 -justify right

        # insert value
        entry_insert .pw.fsimage_info.version.e$key $value

        grid .pw.fsimage_info.version.l$key -row $row -column 0 -sticky w -padx 5
        grid .pw.fsimage_info.version.e$key -row $row -column 1 -sticky e -padx 5

        incr row 1
    }

    grid columnconfigure .pw.fsimage_info.version 1 -weight 1
}

# get name section
proc get_fsimage_name {fsimage_dom_root} {
    # get name item values
    set namespace_id [$fsimage_dom_root selectNodes string(/fsimage/NameSection/namespaceId)]
    set genstamp_v1 [$fsimage_dom_root selectNodes string(/fsimage/NameSection/genstampV1)]
    set genstamp_v2 [$fsimage_dom_root selectNodes string(/fsimage/NameSection/genstampV2)]
    set genstamp_v1_limit [$fsimage_dom_root selectNodes string(/fsimage/NameSection/genstampV1Limit)]
    set last_allocated_block_id [$fsimage_dom_root selectNodes string(/fsimage/NameSection/lastAllocatedBlockId)]
    set tx_id [$fsimage_dom_root selectNodes string(/fsimage/NameSection/txid)]

    # set name dict
    set fsimage_name [dict create "Namespace ID" $namespace_id "GenStamp V1" $genstamp_v1 "GenStamp V2" $genstamp_v2 "GenStamp V1 Limit" $genstamp_v1_limit "Last Allocated Block ID" $last_allocated_block_id "Transaction ID" $tx_id]

    return $fsimage_name
}

# load fsimage name section UI
proc load_fsimage_name_ui {fsimage_name_dict} {
    # destroy name section label frame if exists already
    if {[winfo exists .pw.fsimage_info.name] == 1} {
        destroy .pw.fsimage_info.name
    }

    # construct labelframe
    labelframe .pw.fsimage_info.name -text "Name Section" -labelanchor n
    grid .pw.fsimage_info.name -row 1 -column 0 -sticky ew

    # fill out data with labels and entries
    set row 0

    dict for {key value} $fsimage_name_dict {
        label .pw.fsimage_info.name.l$key -text $key -justify left
        entry .pw.fsimage_info.name.e$key -width 32 -justify right

        # insert value
        entry_insert .pw.fsimage_info.name.e$key $value

        grid .pw.fsimage_info.name.l$key -row $row -column 0 -sticky w -padx 5
        grid .pw.fsimage_info.name.e$key -row $row -column 1 -sticky e -padx 5

        incr row 1
    }

    grid columnconfigure .pw.fsimage_info.name 1 -weight 1
}

# get inode section - basic inode information only
proc get_fsimage_inode {fsimage_dom_root} {
    # get inode item values
    set last_inode_id [$fsimage_dom_root selectNodes string(/fsimage/INodeSection/lastInodeId)]
    set num_inodes [$fsimage_dom_root selectNodes string(/fsimage/INodeSection/numInodes)]

    # set inode dict
    set fsimage_inode [dict create "Last INode ID" $last_inode_id "Number of INodes" $num_inodes]

    return $fsimage_inode
}

# load fsimage inode section UI
proc load_fsimage_inode_ui {fsimage_inode_dict} {
    # destroy inode section label frame if exists already
    if {[winfo exists .pw.fsimage_info.inode] == 1} {
        destroy .pw.fsimage_info.inode
    }

    # construct labelframe
    labelframe .pw.fsimage_info.inode -text "INode Section" -labelanchor n
    grid .pw.fsimage_info.inode -row 2 -column 0 -sticky ew

    # fill out data with labels and entries
    set row 0

    dict for {key value} $fsimage_inode_dict {
        label .pw.fsimage_info.inode.l$key -text $key -justify left
        entry .pw.fsimage_info.inode.e$key -width 16 -justify right

        # insert value
        entry_insert .pw.fsimage_info.inode.e$key $value

        grid .pw.fsimage_info.inode.l$key -row $row -column 0 -sticky w -padx 5
        grid .pw.fsimage_info.inode.e$key -row $row -column 1 -sticky e -padx 5

        incr row 1
    }

    grid columnconfigure .pw.fsimage_info.inode 1 -weight 1
}

# load fsimage inode details section UI
proc load_fsimage_inode_details_ui {fsimage_dom_root} {
    # destroy inode details section label frame if exists already
    if {[winfo exists .pw.inode_detail] == 1} {
        destroy .pw.inode_detail
    }

    # construct labelframe
    labelframe .pw.inode_detail -text "INode Details Section" -labelanchor n

    # set up tablelist
    tablelist::tablelist .pw.inode_detail.tablelist -columns {0 "ID" 0 "Name" 0 "Type" 0 "Modification Time" 0 "Access Time" 0 "Permission" 0 "Name Quota" 0 "Space Quota" 0 "Replication" 0 "Preferred Block Size" 0 "Storage Policy ID" 0 "Block ID" 0 "Block GenStamp" 0 "Block Bytes"} -showseparators yes -selectbackground cyan -stripebackground #f0f0f0 -movablecolumns yes -xscrollcommand [list .pw.inode_detail.horizontal_sb set] -yscrollcommand [list .pw.inode_detail.vertical_sb set]

    scrollbar .pw.inode_detail.horizontal_sb -orient horizontal -command [list .pw.inode_detail.tablelist xview]
    scrollbar .pw.inode_detail.vertical_sb -orient vertical -command [list .pw.inode_detail.tablelist yview]

    grid .pw.inode_detail.tablelist -row 0 -column 0 -sticky nsew
    grid .pw.inode_detail.horizontal_sb -row 1 -column 0 -sticky nsew
    grid .pw.inode_detail.vertical_sb -row 0 -column 1 -sticky nsew
    grid rowconfigure .pw.inode_detail 0 -weight 1
    grid columnconfigure .pw.inode_detail 0 -weight 1

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

        # handle blocks information and insert data into tablelist
        if {![string equal [$inode_dom selectNodes ./blocks] ""]} {
            foreach inode_block [[$inode_dom selectNodes ./blocks] childNodes] {
                set block_id [$inode_block selectNodes string(./id)]
                set block_genstamp [$inode_block selectNodes string(./genstamp)]
                set block_bytes [$inode_block selectNodes string(./numBytes)]

                set inode_block $inode
                lappend inode_block $block_id $block_genstamp $block_bytes

                .pw.inode_detail.tablelist insert end $inode_block
            }
        } else {
            .pw.inode_detail.tablelist insert end $inode
        }
    }
}

# load fsimage XML into UI - main proc to load everything
proc load_fsimage_ui {} {
    set fsimage_xml_file_path [get_fsimage_xml_file_path]

    if {[info exists fsimage_xml_file_path] == 1 && [string equal $fsimage_xml_file_path ""] == 0} {
        log_progress "info" "FSImage File Path: $fsimage_xml_file_path"

        log_progress "info" "Loading XML data into memory."
        set fsimage_dom_root [get_xml_dom $fsimage_xml_file_path]
        log_progress "info" "XML data loaded."

        # destroy panedwindow widget if exists already
        if {[winfo exists .pw] == 1} {
            destroy .pw
        }

        # set up panedwindow widget
        panedwindow .pw -orient horizontal

        # set up general info labelframe
        if {[winfo exists .pw.fsimage_info] == 1} {
            destroy .pw.fsimage_info
        }

        labelframe .pw.fsimage_info -text "FSImage General Information" -labelanchor n
        grid columnconfigure .pw.fsimage_info 0 -weight 1

        # version section UI
        log_progress "info" "Rendering Version Section UI."
        set fsimage_version_dict [get_fsimage_version $fsimage_dom_root]
        load_fsimage_version_ui $fsimage_version_dict

        # name section UI
        log_progress "info" "Rendering Name Section UI."
        set fsimage_name_dict [get_fsimage_name $fsimage_dom_root]
        load_fsimage_name_ui $fsimage_name_dict

        # inode section UI
        log_progress "info" "Rendering INode Section UI."
        set fsimage_inode_dict [get_fsimage_inode $fsimage_dom_root]
        load_fsimage_inode_ui $fsimage_inode_dict

        # inode details section UI
        log_progress "info" "Rendering INode Details Section UI."
        load_fsimage_inode_details_ui $fsimage_dom_root

        log_progress "info" "Deleting XML DOM tree."
        # clear DOM doc - free memory
        $fsimage_dom_root delete
        log_progress "info" "XML DOM tree deleted."

        # layout the panedwindow widget
        grid .pw -row 0 -column 0 -sticky nsew
        .pw add .pw.fsimage_info
        .pw add .pw.inode_detail

        # enable the save_inode_tsv menu
        .mbar.file entryconfigure 1 -state normal
    }
}

proc save_inode_tsv {} {
    set inode_tsv_file_path [get_inode_tsv_file_path]

    if {[info exists inode_tsv_file_path] == 1 && [string equal $inode_tsv_file_path ""] == 0} {
        log_progress "info" "INode TSV File Path: $inode_tsv_file_path"

        log_progress "info" "Writing INode entry to $inode_tsv_file_path"
        set inode_tsv_file_channel [open $inode_tsv_file_path w]
        log_progress "info" "INode TSV File Channel $inode_tsv_file_channel opened."

        set title {"ID" "Name" "Type" "Modification Time" "Access Time" "Permission" "Name Quota" "Space Quota" "Replication" "Preferred Block Size" "Storage Policy ID" "Block ID" "Block GenStamp" "Block Bytes"}
        puts $inode_tsv_file_channel [::csv::join $title "\t"]

        foreach inode_entry [.pw.inode_detail.tablelist get 0 end] {
            puts $inode_tsv_file_channel [::csv::join $inode_entry "\t"]
        }

        close $inode_tsv_file_channel
        log_progress "info" "INode TSV File Channel $inode_tsv_file_channel closed."

        tk_messageBox -message "INode TSV file $inode_tsv_file_path saved." -type ok -icon info
    }
}

# main UI

grid rowconfigure . 0 -weight 1
grid columnconfigure . 0 -weight 1

# set up menu
menu .mbar
. configure -menu .mbar

.mbar add cascade -label File -menu .mbar.file -underline 0
menu .mbar.file -tearoff 0
.mbar.file add command -label "Open XML File" -command load_fsimage_ui
.mbar.file add command -label "Save INode Details as TSV File" -state disabled -command save_inode_tsv
.mbar.file add separator
.mbar.file add command -label "Exit" -command exit
